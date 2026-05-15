-- game-night Supabase schema
--
-- Run this once in the Supabase SQL editor to bootstrap a project.
-- Idempotent: safe to re-run after schema changes (uses create-or-replace
-- where possible). The `games` table is the only stateful object.
--
-- Security model: anon clients are NOT granted any direct table access.
-- Reads and writes go through four security-definer RPCs that take a code
-- (or array of codes) as input. This blocks bulk listing — the only way to
-- see a row is to know its code.

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- table
-- -----------------------------------------------------------------------------

create table if not exists public.games (
  code        text primary key,
  kind        text not null check (kind in ('yahtzee','phase10')),
  state       jsonb not null,
  schema_ver  smallint not null default 1,
  game_over   boolean generated always as ((state->>'gameOver')::boolean) stored,
  started_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  ended_at    timestamptz,
  rev         bigint not null default 1,
  -- Abuse cap: prevent multi-megabyte payloads. A real game state is
  -- well under 50 KB; 256 KB leaves comfortable headroom for future
  -- shape growth without inviting garbage.
  constraint games_state_size_ok check (octet_length(state::text) <= 262144)
);

-- Belt-and-suspenders for an existing table that pre-dates the constraint.
do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'games_state_size_ok' and conrelid = 'public.games'::regclass
  ) then
    alter table public.games
      add constraint games_state_size_ok
      check (octet_length(state::text) <= 262144);
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- abuse rate limit: per-day cap on create_game calls
-- -----------------------------------------------------------------------------
-- The anon key is public, so anyone could spam create_game. We bucket by
-- (day, key fingerprint) and refuse beyond a generous personal-scale cap.
-- The key fingerprint is the request's anon JWT `sub` claim if present, else
-- a constant — coarse, but it's enough to stop dumb scripts.
create table if not exists public.creates_per_day (
  day       date not null,
  bucket    text not null,
  n         integer not null default 0,
  primary key (day, bucket)
);

-- Lock down direct access — only the security-definer function below can
-- touch this table. Without this, anon could SELECT the counter (low-risk
-- but still a leak) and Supabase warns on any RLS-less public table.
alter table public.creates_per_day enable row level security;
revoke all on public.creates_per_day from anon, authenticated;

-- Cap: 200 new games per day across all anon callers. A normal game-night
-- session is <10. Bump if you legitimately need more.
create or replace function public.creates_per_day_check()
returns void language plpgsql as $$
declare
  cur integer;
  max_per_day constant integer := 200;
begin
  insert into public.creates_per_day (day, bucket, n)
    values (current_date, 'anon', 1)
    on conflict (day, bucket)
    do update set n = creates_per_day.n + 1
    returning creates_per_day.n into cur;
  if cur > max_per_day then
    raise exception 'rate limit exceeded' using errcode = '54000';
  end if;
end$$;

create index if not exists games_kind_gameover_endedat_idx
  on public.games (kind, game_over, ended_at desc nulls last);

-- bump rev + updated_at on every UPDATE; ended_at is set by the client
create or replace function public.bump_games_rev()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  new.rev := coalesce(old.rev, 0) + 1;
  return new;
end$$;

drop trigger if exists games_bump_rev on public.games;
create trigger games_bump_rev
  before update on public.games
  for each row execute function public.bump_games_rev();

-- -----------------------------------------------------------------------------
-- RLS: anon has no direct table access — only RPCs
-- -----------------------------------------------------------------------------

alter table public.games enable row level security;
revoke all on public.games from anon;

-- -----------------------------------------------------------------------------
-- RPCs
-- -----------------------------------------------------------------------------

create or replace function public.get_game(p_code text)
returns table(code text, kind text, state jsonb, rev bigint,
              updated_at timestamptz, schema_ver smallint)
language sql security definer set search_path = public as $$
  select g.code, g.kind, g.state, g.rev, g.updated_at, g.schema_ver
  from public.games g where g.code = p_code limit 1
$$;

create or replace function public.create_game(p_kind text, p_state jsonb, p_code text)
returns table(code text, rev bigint, updated_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if p_kind not in ('yahtzee','phase10') then
    raise exception 'bad kind: %', p_kind;
  end if;
  if length(p_code) <> 6 then
    raise exception 'bad code length: %', length(p_code);
  end if;
  perform public.creates_per_day_check();
  insert into public.games(code, kind, state) values (p_code, p_kind, p_state);
  return query select p_code, 1::bigint, now();
end$$;

create or replace function public.save_game(p_code text, p_state jsonb, p_expected_rev bigint)
returns table(rev bigint, updated_at timestamptz, conflict boolean)
language plpgsql security definer set search_path = public as $$
declare
  new_rev bigint;
  new_ts  timestamptz;
begin
  update public.games
     set state    = p_state,
         ended_at = case
                      when (p_state->>'gameOver')::boolean and ended_at is null
                        then now()
                      else ended_at
                    end
   where code = p_code and rev = p_expected_rev
   returning rev, updated_at into new_rev, new_ts;

  if not found then
    return query
      select g.rev, g.updated_at, true
      from public.games g where g.code = p_code;
  else
    return query select new_rev, new_ts, false;
  end if;
end$$;

create or replace function public.list_completed_by_codes(p_kind text, p_codes text[])
returns table(code text, state jsonb, ended_at timestamptz, updated_at timestamptz)
language sql security definer set search_path = public as $$
  select g.code, g.state, g.ended_at, g.updated_at
  from public.games g
  where g.kind = p_kind
    and g.code = any(p_codes)
    and g.game_over = true
  order by g.ended_at desc nulls last
  limit 50
$$;

-- -----------------------------------------------------------------------------
-- grants: anon can only execute the RPCs
-- -----------------------------------------------------------------------------

revoke all on function public.get_game(text)                               from public;
revoke all on function public.create_game(text, jsonb, text)               from public;
revoke all on function public.save_game(text, jsonb, bigint)               from public;
revoke all on function public.list_completed_by_codes(text, text[])        from public;

grant execute on function public.get_game(text)                            to anon;
grant execute on function public.create_game(text, jsonb, text)            to anon;
grant execute on function public.save_game(text, jsonb, bigint)            to anon;
grant execute on function public.list_completed_by_codes(text, text[])     to anon;
