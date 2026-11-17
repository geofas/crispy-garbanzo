-- Nudgy Timer waitlist.
-- Run once in the Supabase project that backs the website.
--
-- The table is closed to the API: row level security is on and there are no
-- policies, so the publishable (anon) key can neither read nor write it.
-- The only way in is join_waitlist(), which can add one address and nothing else.

create table if not exists public.waitlist_signups (
  id          bigint generated always as identity primary key,
  email       text        not null,
  source      text        not null default 'site',
  consent_at  timestamptz not null default now(),
  constraint waitlist_signups_email_format check (email ~ '^[^\s@]+@[^\s@]+\.[^\s@]{2,}$'),
  constraint waitlist_signups_email_length check (char_length(email) <= 254),
  constraint waitlist_signups_email_lower  check (email = lower(email))
);

create unique index if not exists waitlist_signups_email_key
  on public.waitlist_signups (email);

alter table public.waitlist_signups enable row level security;

revoke all on public.waitlist_signups from anon, authenticated;

create or replace function public.join_waitlist(p_email text, p_source text default 'site')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.waitlist_signups (email, source)
  values (lower(trim(p_email)), left(coalesce(nullif(trim(p_source), ''), 'site'), 40))
  on conflict (email) do nothing;
end;
$$;

revoke all on function public.join_waitlist(text, text) from public;
grant execute on function public.join_waitlist(text, text) to anon;
