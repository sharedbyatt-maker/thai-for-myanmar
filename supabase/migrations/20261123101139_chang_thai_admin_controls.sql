-- App metadata is set through the Auth admin API and cannot be edited by users.
create table public.chang_thai_controls (
    id integer primary key default 1 check (id = 1),
    revision bigint not null default 0 check (revision >= 0),
    settings jsonb not null default '{}'::jsonb
        check (jsonb_typeof(settings) = 'object' and octet_length(settings::text) <= 131072),
    updated_at timestamptz not null default now()
);
create table public.chang_thai_admin_draft (
    id integer primary key default 1 check (id = 1),
    revision bigint not null default 0 check (revision >= 0),
    settings jsonb not null default '{}'::jsonb
        check (jsonb_typeof(settings) = 'object' and octet_length(settings::text) <= 131072),
    updated_at timestamptz not null default now()
);

alter table public.chang_thai_controls enable row level security;
alter table public.chang_thai_admin_draft enable row level security;
revoke all on public.chang_thai_controls, public.chang_thai_admin_draft from anon, authenticated;
grant select on public.chang_thai_controls to anon, authenticated;
grant update (settings) on public.chang_thai_controls to authenticated;
grant select on public.chang_thai_admin_draft to authenticated;
grant update (settings) on public.chang_thai_admin_draft to authenticated;

insert into public.chang_thai_controls (id) values (1);
insert into public.chang_thai_admin_draft (id) values (1);

create policy "Read published controls" on public.chang_thai_controls
    for select to anon, authenticated using (true);
create policy "Owner publishes controls" on public.chang_thai_controls
    for update to authenticated
    using ((select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb)
    with check ((select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb);
create policy "Owner reads drafts" on public.chang_thai_admin_draft
    for select to authenticated
    using ((select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb);
create policy "Owner updates drafts" on public.chang_thai_admin_draft
    for update to authenticated
    using ((select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb)
    with check ((select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb);

create or replace function league_private.chang_thai_control_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.revision := old.revision + 1;
    new.updated_at := now();
    return new;
end;
$$;
revoke all on function league_private.chang_thai_control_revision() from public;

create trigger chang_thai_controls_revision before update on public.chang_thai_controls
for each row execute function league_private.chang_thai_control_revision();
create trigger chang_thai_admin_draft_revision before update on public.chang_thai_admin_draft
for each row execute function league_private.chang_thai_control_revision();

-- Public media contains only released or release-candidate lesson audio.
-- Unique object names and INSERT-only access keep published audio URLs immutable.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chang-thai-lesson-audio', 'chang-thai-lesson-audio', true, 5242880, array['audio/mpeg']);
create policy "Owner uploads versioned lesson audio" on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'chang-thai-lesson-audio'
        and (select auth.jwt() -> 'app_metadata' ->> 'chang_thai_admin') = 'true' and (select auth.jwt() -> 'amr') @> '[{"method":"password"}]'::jsonb
        and name ~ '^[a-zA-Z0-9_-]+[.]mp3$'
    );

-- A published revision may be pushed only once, even with simultaneous requests.
create table public.chang_thai_push_sends (
    revision bigint primary key,
    requested_at timestamptz not null default now(),
    status text not null default 'sending' check (status in ('sending', 'sent', 'failed')),
    firebase_message text
);
alter table public.chang_thai_push_sends enable row level security;
revoke all on public.chang_thai_push_sends from anon, authenticated;
grant select, insert, update on public.chang_thai_push_sends to service_role;
