-- Fidelidade, meta de recompensa e avaliações usadas pelo web-client.
-- Pontos só mudam por trigger (uma vez por agendamento). Cliente não escreve o saldo.

create table if not exists public.loyalty_settings (
  barbershop_id uuid primary key references public.barbershops (id) on delete cascade,
  reward_at integer not null default 1500 check (reward_at > 0),
  points_per_completed_visit integer not null default 50 check (points_per_completed_visit >= 0)
);

insert into public.loyalty_settings (barbershop_id)
select id from public.barbershops
on conflict (barbershop_id) do nothing;

create table if not exists public.loyalty_accounts (
  user_id uuid not null references public.users (id) on delete cascade,
  barbershop_id uuid not null references public.barbershops (id) on delete cascade,
  points integer not null default 0 check (points >= 0),
  member_since date not null default current_date,
  updated_at timestamptz not null default now(),
  primary key (user_id, barbershop_id)
);

create table if not exists public.loyalty_events (
  id uuid primary key default gen_random_uuid(),
  barbershop_id uuid not null references public.barbershops (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  agendamento_id uuid not null unique,
  points integer not null check (points >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.barber_reviews (
  id uuid primary key default gen_random_uuid(),
  barbershop_id uuid not null references public.barbershops (id) on delete cascade,
  barbeiro_id uuid not null,
  cliente_id uuid not null references public.users (id) on delete cascade,
  agendamento_id uuid not null unique,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

create index if not exists barber_reviews_barber_idx
  on public.barber_reviews (barbershop_id, barbeiro_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'barber_reviews_agendamento_fk'
  ) then
    alter table public.barber_reviews
      add constraint barber_reviews_agendamento_fk
      foreign key (agendamento_id) references public.agendamentos (id) on delete cascade;
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'barber_reviews_barbeiro_fk'
  ) then
    alter table public.barber_reviews
      add constraint barber_reviews_barbeiro_fk
      foreign key (barbeiro_id) references public.barbeiros (id) on delete cascade;
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'loyalty_events_agendamento_fk'
  ) then
    alter table public.loyalty_events
      add constraint loyalty_events_agendamento_fk
      foreign key (agendamento_id) references public.agendamentos (id) on delete cascade;
  end if;
end
$$;

alter table public.users
  add column if not exists avatar_url text;

alter table public.loyalty_settings enable row level security;
alter table public.loyalty_accounts enable row level security;
alter table public.loyalty_events enable row level security;
alter table public.barber_reviews enable row level security;

drop policy if exists loyalty_settings_public_read on public.loyalty_settings;
create policy loyalty_settings_public_read
  on public.loyalty_settings
  for select
  to anon, authenticated
  using (true);

drop policy if exists loyalty_settings_admin_write on public.loyalty_settings;
create policy loyalty_settings_admin_write
  on public.loyalty_settings
  for all
  to authenticated
  using (public.is_admin_for_tenant(barbershop_id))
  with check (public.is_admin_for_tenant(barbershop_id));

drop policy if exists loyalty_accounts_read_own on public.loyalty_accounts;
create policy loyalty_accounts_read_own
  on public.loyalty_accounts
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin_for_tenant(barbershop_id)
  );

drop policy if exists loyalty_events_read_own on public.loyalty_events;
create policy loyalty_events_read_own
  on public.loyalty_events
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin_for_tenant(barbershop_id)
  );

drop policy if exists barber_reviews_public_read on public.barber_reviews;
create policy barber_reviews_public_read
  on public.barber_reviews
  for select
  to anon, authenticated
  using (true);

drop policy if exists barber_reviews_insert_own on public.barber_reviews;
create policy barber_reviews_insert_own
  on public.barber_reviews
  for insert
  to authenticated
  with check (
    cliente_id = auth.uid()
    and exists (
      select 1
        from public.agendamentos a
       where a.id = agendamento_id
         and a.cliente_id = auth.uid()
         and a.barbeiro_id = barbeiro_id
         and a.barbershop_id = barber_reviews.barbershop_id
         and lower(coalesce(a.status::text, '')) in (
           'confirmado', 'concluido', 'completed', 'finalizado'
         )
    )
  );

grant select on public.loyalty_settings to anon, authenticated;
grant select on public.loyalty_accounts to authenticated;
grant select on public.loyalty_events to authenticated;
grant select on public.barber_reviews to anon, authenticated;
grant insert on public.barber_reviews to authenticated;

create or replace function public.award_loyalty_for_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points integer;
  v_status text := lower(coalesce(new.status::text, ''));
begin
  if v_status not in ('confirmado', 'concluido', 'completed', 'finalizado') then
    return new;
  end if;
  if new.cliente_id is null or new.barbershop_id is null or new.id is null then
    return new;
  end if;

  select s.points_per_completed_visit
    into v_points
    from public.loyalty_settings s
   where s.barbershop_id = new.barbershop_id;
  v_points := coalesce(v_points, 50);

  insert into public.loyalty_accounts (user_id, barbershop_id, points, member_since)
  values (new.cliente_id, new.barbershop_id, 0, current_date)
  on conflict (user_id, barbershop_id) do nothing;

  insert into public.loyalty_events (barbershop_id, user_id, agendamento_id, points)
  values (new.barbershop_id, new.cliente_id, new.id, v_points)
  on conflict (agendamento_id) do nothing;

  if found then
    update public.loyalty_accounts
       set points = points + v_points,
           updated_at = now()
     where user_id = new.cliente_id
       and barbershop_id = new.barbershop_id;
  end if;

  return new;
exception
  when foreign_key_violation then
    return new;
end;
$$;

drop trigger if exists agendamentos_award_loyalty on public.agendamentos;
create trigger agendamentos_award_loyalty
  after insert or update of status on public.agendamentos
  for each row
  execute function public.award_loyalty_for_booking();

create or replace function public.barber_rating_summary(p_barbershop_id uuid)
returns table (
  barbeiro_id uuid,
  rating numeric,
  reviews integer
)
language sql
stable
security definer
set search_path = public
as $$
  select r.barbeiro_id,
         round(avg(r.rating)::numeric, 1) as rating,
         count(*)::integer as reviews
    from public.barber_reviews r
   where r.barbershop_id = p_barbershop_id
   group by r.barbeiro_id;
$$;

create or replace function public.occupied_slot_times(
  p_barbershop_id uuid,
  p_barber_id uuid,
  p_day date
)
returns table (slot text)
language sql
stable
security definer
set search_path = public
as $$
  select to_char(a.data_inicio at time zone 'America/Sao_Paulo', 'HH24:MI')
    from public.agendamentos a
   where a.barbershop_id = p_barbershop_id
     and a.barbeiro_id = p_barber_id
     and (a.data_inicio at time zone 'America/Sao_Paulo')::date = p_day
     and lower(coalesce(a.status::text, '')) not in ('cancelado', 'cancelled');
$$;

revoke all on function public.award_loyalty_for_booking() from public;
revoke all on function public.barber_rating_summary(uuid) from public;
revoke all on function public.occupied_slot_times(uuid, uuid, date) from public;
grant execute on function public.barber_rating_summary(uuid) to anon, authenticated;
grant execute on function public.occupied_slot_times(uuid, uuid, date) to anon, authenticated;
