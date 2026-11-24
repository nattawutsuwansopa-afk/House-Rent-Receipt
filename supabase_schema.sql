-- Run in Supabase SQL Editor, as project owner.
-- Keep Row Level Security enabled and use only the publishable/anon key in the browser.
create table if not exists public.rent_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  profile_name text not null,
  receipt_id text not null,
  receipt_data jsonb not null,
  saved_at timestamptz not null default now(),
  primary key (user_id, profile_name, receipt_id)
);
alter table public.rent_receipts enable row level security;
create policy "Own receipts read" on public.rent_receipts for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own receipts insert" on public.rent_receipts for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Own receipts update" on public.rent_receipts for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Own receipts delete" on public.rent_receipts for delete to authenticated using ((select auth.uid()) = user_id);
grant select, insert, update, delete on public.rent_receipts to authenticated;

-- Reject duplicate book/receipt numbers in the same online account/profile,
-- including numerically equivalent strings such as 0001 and 1.
-- If old duplicate rows exist, clean them up before creating this index.
create unique index if not exists rent_receipts_unique_book_number
on public.rent_receipts (
  user_id, profile_name,
  (lower(btrim(receipt_data->>'book'))),
  (case when (receipt_data->>'number') ~ '^[0-9]+$'
    then coalesce(nullif(ltrim(receipt_data->>'number', '0'), ''), '0')
    else lower(btrim(receipt_data->>'number')) end)
);
