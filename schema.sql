-- ============================================================
--  ROYALE — Supabase schema
--  Run once in the Supabase SQL editor before connecting the app.
-- ============================================================

create table if not exists bookings (
  id          text primary key,
  customer    text,
  vehicle     text,
  source      text,                     -- 'own' | 'external'
  type        text,                     -- 'rental' | 'chauffeur'
  service     text,                     -- One way / Two way / 5 hours / 10 hours / Multiple day
  start_date  date,
  start_time  text,
  end_date    date,
  total       numeric default 0,        -- charged to customer
  collected   numeric default 0,        -- paid so far
  received    numeric,                  -- landed in bank; null = no fees
  cost        numeric,                  -- owner payout; null = not recorded
  notes       text,
  updated_at  timestamptz default now()
);

create table if not exists costs (
  id          text primary key,
  amount      numeric default 0,
  type        text,
  note        text,
  cost_date   date,
  linked      text,                     -- booking/revenue id for derived fee rows
  updated_at  timestamptz default now()
);

create table if not exists revenue (
  id          text primary key,
  amount      numeric default 0,        -- charged
  received    numeric,                  -- landed in bank; null = no fees
  type        text,
  car         text,
  note        text,
  rev_date    date,
  updated_at  timestamptz default now()
);

create table if not exists personal (
  id          text primary key,
  kind        text,                     -- 'revenue' (draw in) | 'expense' (spend)
  amount      numeric default 0,
  type        text,
  note        text,
  p_date      date,
  updated_at  timestamptz default now()
);

create table if not exists settings (
  id      int primary key default 1,
  target  numeric default 34000,        -- monthly fixed base
  budget  numeric default 3000          -- personal budget
);

insert into settings (id, target, budget)
values (1, 34000, 3000)
on conflict (id) do nothing;

create index if not exists bookings_start_idx on bookings (start_date);
create index if not exists costs_date_idx     on costs (cost_date);
create index if not exists revenue_date_idx   on revenue (rev_date);
create index if not exists personal_date_idx  on personal (p_date);


-- ============================================================
--  ROW LEVEL SECURITY
--  The anon key is public by design, so RLS is what actually
--  protects the data. Pick ONE of the two options below.
-- ============================================================

alter table bookings enable row level security;
alter table costs    enable row level security;
alter table revenue  enable row level security;
alter table personal enable row level security;
alter table settings enable row level security;

-- ---- OPTION A — open access (anyone with the link can read/write) ----
-- Fine while it is just you and your partner and the URL is private.
-- Note: 'personal' is included here, so anyone with the link sees it.
-- Leave the personal policy out if you would rather keep that tab local.

create policy "open bookings" on bookings for all using (true) with check (true);
create policy "open costs"    on costs    for all using (true) with check (true);
create policy "open revenue"  on revenue  for all using (true) with check (true);
create policy "open settings" on settings for all using (true) with check (true);
create policy "open personal" on personal for all using (true) with check (true);

-- ---- OPTION B — signed-in users only (recommended once it matters) ----
-- Drop the policies above, turn on email auth in Supabase, then:
--
-- create policy "auth bookings" on bookings for all
--   using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- ...repeat for costs, revenue, settings, personal.
