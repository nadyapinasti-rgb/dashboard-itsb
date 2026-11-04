-- ITSB Social Media Dashboard: shared team workspace
-- Run once in Supabase SQL Editor.
create table if not exists public.workspace_members (
  workspace_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'editor' check (role in ('owner','editor','viewer')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.app_data (
  workspace_id uuid not null,
  data_key text not null check (data_key in ('settings','tracker','insight','followers','prodi')),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (workspace_id, data_key)
);

alter table public.workspace_members enable row level security;
alter table public.app_data enable row level security;
grant select on public.workspace_members to authenticated;
grant select, insert, update, delete on public.app_data to authenticated;

drop policy if exists "Members can read own membership" on public.workspace_members;
create policy "Members can read own membership" on public.workspace_members
for select to authenticated using (user_id = auth.uid());

drop policy if exists "Workspace members can read shared data" on public.app_data;
create policy "Workspace members can read shared data" on public.app_data
for select to authenticated using (
  exists (select 1 from public.workspace_members m
          where m.workspace_id = app_data.workspace_id and m.user_id = auth.uid())
);

drop policy if exists "Editors can insert shared data" on public.app_data;
create policy "Editors can insert shared data" on public.app_data
for insert to authenticated with check (
  exists (select 1 from public.workspace_members m
          where m.workspace_id = app_data.workspace_id and m.user_id = auth.uid()
          and m.role in ('owner','editor'))
);

drop policy if exists "Editors can update shared data" on public.app_data;
create policy "Editors can update shared data" on public.app_data
for update to authenticated using (
  exists (select 1 from public.workspace_members m
          where m.workspace_id = app_data.workspace_id and m.user_id = auth.uid()
          and m.role in ('owner','editor'))
) with check (
  exists (select 1 from public.workspace_members m
          where m.workspace_id = app_data.workspace_id and m.user_id = auth.uid()
          and m.role in ('owner','editor'))
);

drop policy if exists "Owners can delete shared data" on public.app_data;
create policy "Owners can delete shared data" on public.app_data
for delete to authenticated using (
  exists (select 1 from public.workspace_members m
          where m.workspace_id = app_data.workspace_id and m.user_id = auth.uid()
          and m.role = 'owner')
);

-- After inviting team members in Supabase Authentication > Users,
-- add each account to this workspace by running an INSERT like below.
-- Workspace ID: c4966757-b261-46af-846e-812b2412a75d
-- Replace USER_UUID with the user's UUID from Authentication > Users.
-- First administrator:
-- insert into public.workspace_members (workspace_id, user_id, role)
-- values ('c4966757-b261-46af-846e-812b2412a75d', 'USER_UUID', 'owner');
-- Other members: use role 'editor' or 'viewer'.

-- Enable public.app_data in Database > Publications > supabase_realtime
-- so the dashboard can receive changes made by other team members.
