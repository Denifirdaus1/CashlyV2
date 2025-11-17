-- ============================================
-- EXTENSION
-- ============================================
create extension if not exists "pgcrypto";

-- ============================================
-- ENUM TYPES
-- ============================================

-- Cashflow: pemasukan/pengeluaran
do $$
begin
  if not exists (select 1 from pg_type where typname = 'cash_transaction_type') then
    create type cash_transaction_type as enum ('income', 'expense');
  end if;
end$$;

-- Savings: setor/tarik
do $$
begin
  if not exists (select 1 from pg_type where typname = 'saving_entry_type') then
    create type saving_entry_type as enum ('deposit', 'withdraw');
  end if;
end$$;

-- ============================================
-- 0. APP USERS (OPTIONAL, PREP FOR MULTI-USER)
-- ============================================

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  -- bisa di-map ke auth.users.id nanti
  auth_user_id uuid,
  display_name text,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_app_users_auth_user_id
  on public.app_users (auth_user_id);

-- ============================================
-- 1. CASHFLOW: KATEGORI & TRANSAKSI
-- ============================================

create table if not exists public.cash_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.app_users(id) on delete set null,
  name text not null,
  -- 'income' atau 'expense' biar kategori jelas
  type cash_transaction_type not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_cash_categories_user_id
  on public.cash_categories (user_id);


create table if not exists public.cash_transactions (
  id uuid primary key default gen_random_uuid(),

  user_id uuid references public.app_users(id) on delete set null,

  transaction_date date not null,

  -- simpan dalam "cents": Rp 10.000 -> 1_000_000
  amount_cents bigint not null check (amount_cents >= 0),

  type cash_transaction_type not null,

  category_id uuid references public.cash_categories(id) on delete set null,

  note text,

  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz
);

-- Index penting buat performance:
-- 1) filter berdasarkan user dan tanggal
create index if not exists idx_cash_transactions_user_date
  on public.cash_transactions (user_id, transaction_date desc);

-- 2) filter berdasarkan kategori
create index if not exists idx_cash_transactions_category
  on public.cash_transactions (category_id);

-- 3) filter berdasarkan type
create index if not exists idx_cash_transactions_type
  on public.cash_transactions (type);

-- ============================================
-- 2. TABUNGAN PRIBADI
-- ============================================

create table if not exists public.saving_personal_goals (
  id uuid primary key default gen_random_uuid(),

  user_id uuid references public.app_users(id) on delete set null,

  name text not null,
  description text,

  -- target total (dalam cents)
  target_amount_cents bigint not null check (target_amount_cents >= 0),

  deadline date,

  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz
);

create index if not exists idx_saving_personal_goals_user
  on public.saving_personal_goals (user_id);


create table if not exists public.saving_personal_entries (
  id uuid primary key default gen_random_uuid(),

  user_id uuid references public.app_users(id) on delete set null,

  goal_id uuid not null references public.saving_personal_goals(id) on delete cascade,

  transaction_date date not null,

  amount_cents bigint not null check (amount_cents >= 0),

  type saving_entry_type not null, -- 'deposit' / 'withdraw'

  note text,

  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz
);

create index if not exists idx_saving_personal_entries_goal
  on public.saving_personal_entries (goal_id, transaction_date desc);

create index if not exists idx_saving_personal_entries_user
  on public.saving_personal_entries (user_id, transaction_date desc);

-- ============================================
-- 3. TABUNGAN KELOMPOK
-- ============================================

create table if not exists public.saving_groups (
  id uuid primary key default gen_random_uuid(),

  -- admin pembuat kelompok
  admin_user_id uuid references public.app_users(id) on delete set null,

  name text not null,
  description text,

  -- target total kelompok (dalam cents)
  target_total_cents bigint not null check (target_total_cents >= 0),

  deadline date,

  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz
);

create index if not exists idx_saving_groups_admin
  on public.saving_groups (admin_user_id);


create table if not exists public.saving_group_members (
  id uuid primary key default gen_random_uuid(),

  group_id uuid not null references public.saving_groups(id) on delete cascade,

  display_name text not null,

  -- target per anggota (boleh null kalau pakai pembagian rata di app)
  target_amount_cents bigint check (target_amount_cents is null or target_amount_cents >= 0),

  created_at timestamptz not null default now()
);

create index if not exists idx_saving_group_members_group
  on public.saving_group_members (group_id);


create table if not exists public.saving_group_entries (
  id uuid primary key default gen_random_uuid(),

  group_id uuid not null references public.saving_groups(id) on delete cascade,

  member_id uuid not null references public.saving_group_members(id) on delete cascade,

  transaction_date date not null,

  amount_cents bigint not null check (amount_cents >= 0),

  type saving_entry_type not null,

  note text,

  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz
);

create index if not exists idx_saving_group_entries_group_date
  on public.saving_group_entries (group_id, transaction_date desc);

create index if not exists idx_saving_group_entries_member_date
  on public.saving_group_entries (member_id, transaction_date desc);

-- ============================================
-- 4. VIEW RINGKASAN (BIAR QUERY DARI FLUTTER SIMPLE)
-- ============================================

-- Ringkasan cashflow per hari per user
create or replace view public.vw_cash_daily_summary as
select
  user_id,
  transaction_date,
  sum(case when type = 'income' then amount_cents else 0 end) as total_income_cents,
  sum(case when type = 'expense' then amount_cents else 0 end) as total_expense_cents,
  sum(case when type = 'income' then amount_cents else -amount_cents end) as balance_cents
from public.cash_transactions
where deleted_at is null
group by user_id, transaction_date;


-- Ringkasan per goal tabungan pribadi
create or replace view public.vw_saving_personal_goal_summary as
select
  g.id as goal_id,
  g.user_id,
  g.name,
  g.target_amount_cents,
  coalesce(
    sum(
      case when e.type = 'deposit' then e.amount_cents
           when e.type = 'withdraw' then -e.amount_cents
           else 0 end
    ), 0
  ) as current_amount_cents
from public.saving_personal_goals g
left join public.saving_personal_entries e
  on e.goal_id = g.id
  and e.deleted_at is null
group by g.id, g.user_id, g.name, g.target_amount_cents;


-- Ringkasan per anggota per kelompok
create or replace view public.vw_saving_group_member_summary as
select
  m.id as member_id,
  m.group_id,
  m.display_name,
  m.target_amount_cents,
  coalesce(
    sum(
      case when e.type = 'deposit' then e.amount_cents
           when e.type = 'withdraw' then -e.amount_cents
           else 0 end
    ), 0
  ) as total_contributed_cents
from public.saving_group_members m
left join public.saving_group_entries e
  on e.member_id = m.id
  and e.deleted_at is null
group by m.id, m.group_id, m.display_name, m.target_amount_cents;


-- Ringkasan per kelompok
create or replace view public.vw_saving_group_summary as
select
  g.id as group_id,
  g.admin_user_id,
  g.name,
  g.target_total_cents,
  count(distinct m.id) as member_count,
  coalesce(
    sum(
      case when e.type = 'deposit' then e.amount_cents
           when e.type = 'withdraw' then -e.amount_cents
           else 0 end
    ), 0
  ) as total_contributed_cents
from public.saving_groups g
left join public.saving_group_members m
  on m.group_id = g.id
left join public.saving_group_entries e
  on e.group_id = g.id
  and e.deleted_at is null
group by g.id, g.admin_user_id, g.name, g.target_total_cents;
