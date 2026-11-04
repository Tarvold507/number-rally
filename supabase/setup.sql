-- Number Rally family sync — run once in the Supabase SQL Editor.
-- Each kid's progress is stored under a family ID, which is a SHA-256 hash of the
-- family code computed in the app. The code itself never reaches the database.
-- The table is locked (row level security on, no policies, no grants); the app
-- only uses the three functions below.

create table if not exists public.nr_kids (
  family_id  text        not null check (family_id ~ '^[0-9a-f]{64}$'),
  kid_id     text        not null check (kid_id ~ '^[A-Za-z0-9_-]{1,40}$'),
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (family_id, kid_id)
);

alter table public.nr_kids enable row level security;
revoke all on table public.nr_kids from anon, authenticated;

-- Save (or replace) one kid's progress.
create or replace function public.nr_put_kid(fam text, kid text, payload jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if fam !~ '^[0-9a-f]{64}$' or kid !~ '^[A-Za-z0-9_-]{1,40}$' then
    raise exception 'Invalid family or player ID';
  end if;
  if payload ->> 'id' is distinct from kid then
    raise exception 'Player ID does not match';
  end if;
  if pg_column_size(payload) > 300000 then
    raise exception 'Progress data is too large';
  end if;
  insert into public.nr_kids (family_id, kid_id, data, updated_at)
  values (fam, kid, payload, now())
  on conflict (family_id, kid_id)
  do update set data = excluded.data, updated_at = now();
end;
$$;

-- Read every kid in a family.
create or replace function public.nr_get_family(fam text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object('at', (extract(epoch from updated_at) * 1000)::bigint, 'kid', data)
      order by kid_id
    ),
    '[]'::jsonb
  )
  from public.nr_kids
  where family_id = fam and fam ~ '^[0-9a-f]{64}$';
$$;

-- Remove one kid (when a player is deleted on a tablet).
create or replace function public.nr_delete_kid(fam text, kid text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.nr_kids where family_id = fam and kid_id = kid;
$$;

revoke all on function public.nr_put_kid(text, text, jsonb) from public;
revoke all on function public.nr_get_family(text) from public;
revoke all on function public.nr_delete_kid(text, text) from public;
grant execute on function public.nr_put_kid(text, text, jsonb) to anon, authenticated;
grant execute on function public.nr_get_family(text) to anon, authenticated;
grant execute on function public.nr_delete_kid(text, text) to anon, authenticated;
