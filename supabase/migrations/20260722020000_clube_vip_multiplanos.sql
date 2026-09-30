begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  barbershop_id uuid not null references public.barbershops(id) on delete cascade,
  name text not null,
  description text,
  benefits text[] not null default '{}'::text[],
  monthly_amount numeric(12, 2) not null,
  frequency text not null default 'monthly',
  monthly_limit integer,
  active boolean not null default true,
  mp_plan_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint plans_monthly_amount_check check (monthly_amount >= 0),
  constraint plans_frequency_check check (frequency in ('monthly', 'quarterly', 'yearly')),
  constraint plans_monthly_limit_check check (monthly_limit is null or monthly_limit > 0),
  constraint plans_id_barbershop_key unique (id, barbershop_id)
);

-- Compatibilidade com schema legado em português (nome/valor/ativo/...).
do $$
begin
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'nome'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'name'
  ) then
    execute 'alter table public.plans rename column nome to name';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'descricao'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'description'
  ) then
    execute 'alter table public.plans rename column descricao to description';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'valor'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'monthly_amount'
  ) then
    execute 'alter table public.plans rename column valor to monthly_amount';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'frequencia'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'frequency'
  ) then
    execute 'alter table public.plans rename column frequencia to frequency';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'limite_usos'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'monthly_limit'
  ) then
    execute 'alter table public.plans rename column limite_usos to monthly_limit';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'ativo'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'plans' and column_name = 'active'
  ) then
    execute 'alter table public.plans rename column ativo to active';
  end if;
end
$$;

alter table public.plans
  add column if not exists description text,
  add column if not exists benefits text[] not null default '{}'::text[],
  add column if not exists monthly_amount numeric(12, 2),
  add column if not exists frequency text,
  add column if not exists monthly_limit integer,
  add column if not exists active boolean,
  add column if not exists mp_plan_id text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

update public.plans
   set frequency = case lower(trim(coalesce(frequency, '')))
         when 'mensal' then 'monthly'
         when 'trimestral' then 'quarterly'
         when 'anual' then 'yearly'
         when 'monthly' then 'monthly'
         when 'quarterly' then 'quarterly'
         when 'yearly' then 'yearly'
         else 'monthly'
       end;

update public.plans
   set monthly_limit = null
 where monthly_limit is not null and monthly_limit <= 0;

update public.plans
   set monthly_amount = coalesce(monthly_amount, 0)
 where monthly_amount is null;

update public.plans
   set active = coalesce(active, true)
 where active is null;

update public.plans
   set benefits = '{}'::text[]
 where benefits is null;

update public.plans
   set created_at = now()
 where created_at is null;

update public.plans
   set updated_at = now()
 where updated_at is null;

alter table public.plans
  alter column monthly_amount set not null,
  alter column frequency set default 'monthly',
  alter column frequency set not null,
  alter column active set default true,
  alter column active set not null,
  alter column benefits set default '{}'::text[],
  alter column benefits set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'plans_monthly_amount_check'
       and conrelid = 'public.plans'::regclass
  ) then
    alter table public.plans
      add constraint plans_monthly_amount_check check (monthly_amount >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
     where conname = 'plans_frequency_check'
       and conrelid = 'public.plans'::regclass
  ) then
    alter table public.plans
      add constraint plans_frequency_check
      check (frequency in ('monthly', 'quarterly', 'yearly'));
  end if;

  if not exists (
    select 1 from pg_constraint
     where conname = 'plans_monthly_limit_check'
       and conrelid = 'public.plans'::regclass
  ) then
    alter table public.plans
      add constraint plans_monthly_limit_check
      check (monthly_limit is null or monthly_limit > 0);
  end if;

  if not exists (
    select 1 from pg_constraint
     where conname = 'plans_id_barbershop_key'
       and conrelid = 'public.plans'::regclass
  ) then
    alter table public.plans
      add constraint plans_id_barbershop_key unique (id, barbershop_id);
  end if;
end
$$;

create unique index if not exists plans_barbershop_mp_plan_uidx
  on public.plans (barbershop_id, mp_plan_id)
  where mp_plan_id is not null;
create index if not exists plans_barbershop_active_idx
  on public.plans (barbershop_id, active);

drop trigger if exists trg_plans_updated_at on public.plans;
create trigger trg_plans_updated_at
  before update on public.plans
  for each row execute function public.set_updated_at();

-- O schema legado usava subscriptions.plan_id para guardar o ID externo do MP.
do $$
declare
  plan_id_type text;
begin
  if to_regclass('public.subscriptions') is null then
    execute $create$
      create table public.subscriptions (
        id uuid primary key default gen_random_uuid(),
        user_id uuid not null references auth.users(id) on delete cascade,
        barbershop_id uuid not null references public.barbershops(id) on delete cascade,
        plan_id uuid,
        mp_preapproval_id text,
        mp_plan_id text,
        status text not null default 'pending',
        next_payment_date timestamptz,
        cancelled_at timestamptz,
        created_at timestamptz not null default now(),
        updated_at timestamptz not null default now()
      )
    $create$;
  else
    select data_type
      into plan_id_type
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'subscriptions'
       and column_name = 'plan_id';

    if plan_id_type is not null and plan_id_type <> 'uuid' then
      if not exists (
        select 1 from information_schema.columns
         where table_schema = 'public'
           and table_name = 'subscriptions'
           and column_name = 'mp_plan_id'
      ) then
        execute 'alter table public.subscriptions rename column plan_id to mp_plan_id';
      else
        execute $copy$
          update public.subscriptions
             set mp_plan_id = coalesce(mp_plan_id, plan_id::text)
           where plan_id is not null
        $copy$;
        execute 'alter table public.subscriptions drop column plan_id';
      end if;
    end if;
  end if;
end
$$;

alter table public.subscriptions
  add column if not exists id uuid default gen_random_uuid(),
  add column if not exists barbershop_id uuid,
  add column if not exists plan_id uuid,
  add column if not exists mp_preapproval_id text,
  add column if not exists mp_plan_id text,
  add column if not exists status text default 'pending',
  add column if not exists next_payment_date timestamptz,
  add column if not exists cancelled_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

update public.subscriptions set id = gen_random_uuid() where id is null;
update public.subscriptions set status = 'pending' where status is null;
update public.subscriptions set created_at = now() where created_at is null;
update public.subscriptions set updated_at = now() where updated_at is null;

alter table public.subscriptions
  alter column id set default gen_random_uuid(),
  alter column id set not null,
  alter column status set default 'pending',
  alter column status set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- Catálogo equivalente ao plano único legado, inclusive inativo quando o preço
-- não era conhecido. O NOT EXISTS torna a importação repetível.
insert into public.plans (
  barbershop_id,
  name,
  description,
  monthly_amount,
  frequency,
  monthly_limit,
  active,
  mp_plan_id
)
select
  b.id,
  'Clube VIP (legado)',
  'Plano migrado automaticamente da configuração anterior.',
  greatest(coalesce(b.plan_amount, 0), 0),
  'monthly',
  null,
  coalesce(b.plan_amount, 0) > 0 and nullif(trim(b.mp_plan_id), '') is not null,
  nullif(trim(b.mp_plan_id), '')
from public.barbershops b
where (
    coalesce(b.plan_amount, 0) > 0
    or nullif(trim(b.mp_plan_id), '') is not null
  )
  and not exists (
    select 1
      from public.plans p
     where p.barbershop_id = b.id
       and (
         (p.mp_plan_id is not null and p.mp_plan_id = nullif(trim(b.mp_plan_id), ''))
         or (
           nullif(trim(b.mp_plan_id), '') is null
           and p.name = 'Clube VIP (legado)'
         )
       )
  );

update public.subscriptions s
   set plan_id = p.id,
       mp_plan_id = coalesce(s.mp_plan_id, p.mp_plan_id),
       updated_at = now()
  from public.plans p
 where s.plan_id is null
   and s.barbershop_id = p.barbershop_id
   and (
     (s.mp_plan_id is not null and s.mp_plan_id = p.mp_plan_id)
     or (
       s.mp_plan_id is null
       and p.name = 'Clube VIP (legado)'
       and not exists (
         select 1 from public.plans p2
          where p2.barbershop_id = p.barbershop_id
            and p2.id <> p.id
       )
     )
   );

-- Preserva cópia integral de linhas excedentes antes de consolidar a regra
-- de uma assinatura por usuário + barbearia.
create table if not exists public.subscription_migration_archive (
  archive_id uuid primary key default gen_random_uuid(),
  subscription_id uuid,
  original_data jsonb not null,
  reason text not null,
  archived_at timestamptz not null default now()
);

with ranked as (
  select
    ctid,
    id,
    row_number() over (
      partition by user_id, barbershop_id
      order by
        (status in ('authorized', 'active')) desc,
        updated_at desc nulls last,
        created_at desc nulls last,
        id
    ) as rn
  from public.subscriptions
  where user_id is not null and barbershop_id is not null
),
archived as (
  insert into public.subscription_migration_archive (
    subscription_id,
    original_data,
    reason
  )
  select s.id, to_jsonb(s), 'duplicate_user_barbershop'
    from public.subscriptions s
    join ranked r on r.ctid = s.ctid
   where r.rn > 1
     and not exists (
       select 1
         from public.subscription_migration_archive a
        where a.subscription_id = s.id
          and a.reason = 'duplicate_user_barbershop'
     )
  returning subscription_id
)
delete from public.subscriptions s
 using ranked r
 where r.ctid = s.ctid
   and r.rn > 1;

create unique index if not exists subscriptions_id_barbershop_uidx
  on public.subscriptions (id, barbershop_id);
create unique index if not exists subscriptions_user_barbershop_uidx
  on public.subscriptions (user_id, barbershop_id);
create index if not exists subscriptions_plan_idx
  on public.subscriptions (plan_id);
create index if not exists subscriptions_barbershop_status_idx
  on public.subscriptions (barbershop_id, status);

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'subscriptions_plan_tenant_fk'
       and conrelid = 'public.subscriptions'::regclass
  ) then
    alter table public.subscriptions
      add constraint subscriptions_plan_tenant_fk
      foreign key (plan_id, barbershop_id)
      references public.plans (id, barbershop_id)
      on delete restrict
      not valid;
  end if;
end
$$;

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

create unique index if not exists servicos_id_barbershop_uidx
  on public.servicos (id, barbershop_id);

create table if not exists public.plan_services (
  plan_id uuid not null,
  service_id uuid not null,
  barbershop_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (plan_id, service_id),
  constraint plan_services_plan_tenant_fk
    foreign key (plan_id, barbershop_id)
    references public.plans (id, barbershop_id)
    on delete cascade,
  constraint plan_services_service_tenant_fk
    foreign key (service_id, barbershop_id)
    references public.servicos (id, barbershop_id)
    on delete cascade
);

create index if not exists plan_services_tenant_service_idx
  on public.plan_services (barbershop_id, service_id);

alter table public.agendamentos
  add column if not exists covered_by_plan boolean not null default false,
  add column if not exists charged_price numeric(12, 2),
  add column if not exists plan_id uuid,
  add column if not exists subscription_id uuid;

update public.agendamentos a
   set charged_price = coalesce(s.preco, 0)
  from public.servicos s
 where a.charged_price is null
   and s.id = a.servico_id
   and s.barbershop_id = a.barbershop_id;

update public.agendamentos
   set charged_price = 0
 where charged_price is null;

alter table public.agendamentos
  alter column charged_price set default 0,
  alter column charged_price set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'agendamentos_plan_tenant_fk'
       and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_plan_tenant_fk
      foreign key (plan_id, barbershop_id)
      references public.plans (id, barbershop_id)
      on delete restrict
      not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
     where conname = 'agendamentos_subscription_tenant_fk'
       and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_subscription_tenant_fk
      foreign key (subscription_id, barbershop_id)
      references public.subscriptions (id, barbershop_id)
      on delete restrict
      not valid;
  end if;
end
$$;

create index if not exists agendamentos_subscription_month_idx
  on public.agendamentos (subscription_id, data_inicio)
  where covered_by_plan;

create or replace function public.is_admin_for_tenant(p_barbershop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.users u
     where u.id = auth.uid()
       and u.barbershop_id = p_barbershop_id
       and lower(u.role::text) = 'admin'
  );
$$;

revoke all on function public.is_admin_for_tenant(uuid) from public;
grant execute on function public.is_admin_for_tenant(uuid) to authenticated;

alter table public.plans enable row level security;
alter table public.plan_services enable row level security;
alter table public.subscriptions enable row level security;
alter table public.subscription_migration_archive enable row level security;

drop policy if exists plans_select_tenant on public.plans;
create policy plans_select_tenant on public.plans
  for select to authenticated
  using (
    public.is_admin_for_tenant(barbershop_id)
    or (
      active
      and exists (
        select 1 from public.users u
         where u.id = auth.uid()
           and u.barbershop_id = plans.barbershop_id
      )
    )
  );

drop policy if exists plans_admin_insert on public.plans;
create policy plans_admin_insert on public.plans
  for insert to authenticated
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists plans_admin_update on public.plans;
create policy plans_admin_update on public.plans
  for update to authenticated
  using (public.is_admin_for_tenant(barbershop_id))
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists plans_admin_delete on public.plans;
create policy plans_admin_delete on public.plans
  for delete to authenticated
  using (public.is_admin_for_tenant(barbershop_id));

drop policy if exists plan_services_select_tenant on public.plan_services;
create policy plan_services_select_tenant on public.plan_services
  for select to authenticated
  using (
    public.is_admin_for_tenant(barbershop_id)
    or exists (
      select 1
        from public.users u
        join public.plans p
          on p.id = plan_services.plan_id
         and p.barbershop_id = plan_services.barbershop_id
       where u.id = auth.uid()
         and u.barbershop_id = plan_services.barbershop_id
         and p.active
    )
  );
drop policy if exists plan_services_admin_insert on public.plan_services;
create policy plan_services_admin_insert on public.plan_services
  for insert to authenticated
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists plan_services_admin_update on public.plan_services;
create policy plan_services_admin_update on public.plan_services
  for update to authenticated
  using (public.is_admin_for_tenant(barbershop_id))
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists plan_services_admin_delete on public.plan_services;
create policy plan_services_admin_delete on public.plan_services
  for delete to authenticated
  using (public.is_admin_for_tenant(barbershop_id));

drop policy if exists subscriptions_select_own_or_admin on public.subscriptions;
create policy subscriptions_select_own_or_admin on public.subscriptions
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin_for_tenant(barbershop_id)
  );
drop policy if exists subscriptions_admin_update on public.subscriptions;
create policy subscriptions_admin_update on public.subscriptions
  for update to authenticated
  using (public.is_admin_for_tenant(barbershop_id))
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists subscriptions_admin_insert on public.subscriptions;
create policy subscriptions_admin_insert on public.subscriptions
  for insert to authenticated
  with check (public.is_admin_for_tenant(barbershop_id));
drop policy if exists subscriptions_admin_delete on public.subscriptions;
create policy subscriptions_admin_delete on public.subscriptions
  for delete to authenticated
  using (public.is_admin_for_tenant(barbershop_id));

drop policy if exists subscription_archive_admin_select
  on public.subscription_migration_archive;
create policy subscription_archive_admin_select
  on public.subscription_migration_archive
  for select to authenticated
  using (
    exists (
      select 1
        from public.users u
       where u.id = auth.uid()
         and lower(u.role::text) = 'admin'
         and u.barbershop_id::text =
           original_data ->> 'barbershop_id'
    )
  );

create or replace function public.create_vip_booking(
  p_barbershop_id uuid,
  p_barber_id uuid,
  p_service_id uuid,
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_status text default 'confirmado'
)
returns setof public.agendamentos
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_service_price numeric(12, 2);
  v_subscription public.subscriptions%rowtype;
  v_plan public.plans%rowtype;
  v_usage integer := 0;
  v_covered boolean := false;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'Usuário não autenticado.';
  end if;
  if p_start_at is null or p_end_at is null or p_end_at <= p_start_at then
    raise exception using errcode = '22023', message = 'Intervalo do agendamento inválido.';
  end if;
  if p_status is null or trim(p_status) = '' then
    raise exception using errcode = '22023', message = 'Status do agendamento inválido.';
  end if;

  if not exists (
    select 1 from public.users u
     where u.id = v_user_id
       and u.barbershop_id = p_barbershop_id
  ) then
    raise exception using errcode = '42501', message = 'Usuário não pertence à barbearia.';
  end if;
  if not exists (
    select 1 from public.barbeiros b
     where b.id = p_barber_id
       and b.barbershop_id = p_barbershop_id
  ) then
    raise exception using errcode = '23503', message = 'Barbeiro não pertence à barbearia.';
  end if;

  select s.preco
    into v_service_price
    from public.servicos s
   where s.id = p_service_id
     and s.barbershop_id = p_barbershop_id;
  if not found then
    raise exception using errcode = '23503', message = 'Serviço não pertence à barbearia.';
  end if;

  select s.*
    into v_subscription
    from public.subscriptions s
   where s.user_id = v_user_id
     and s.barbershop_id = p_barbershop_id
     and s.status in ('authorized', 'active')
   for update;

  if found and v_subscription.plan_id is not null then
    select p.*
      into v_plan
      from public.plans p
     where p.id = v_subscription.plan_id
       and p.barbershop_id = p_barbershop_id
       and p.active
     for share;

    if found and exists (
      select 1
        from public.plan_services ps
       where ps.plan_id = v_plan.id
         and ps.service_id = p_service_id
         and ps.barbershop_id = p_barbershop_id
    ) then
      select count(*)::integer
        into v_usage
        from public.agendamentos a
       where a.subscription_id = v_subscription.id
         and a.covered_by_plan
         and a.data_inicio >= date_trunc('month', p_start_at)
         and a.data_inicio < date_trunc('month', p_start_at) + interval '1 month'
         and a.status::text not in ('cancelado', 'canceled', 'cancelled');

      v_covered := v_plan.monthly_limit is null
        or v_usage < v_plan.monthly_limit;
    end if;
  end if;

  return query
  insert into public.agendamentos (
    barbershop_id,
    barbeiro_id,
    servico_id,
    cliente_id,
    data_inicio,
    data_fim,
    status,
    covered_by_plan,
    charged_price,
    plan_id,
    subscription_id
  )
  values (
    p_barbershop_id,
    p_barber_id,
    p_service_id,
    v_user_id,
    p_start_at,
    p_end_at,
    p_status::public.booking_status,
    v_covered,
    case when v_covered then 0 else coalesce(v_service_price, 0) end,
    case when v_covered then v_plan.id else null end,
    case when v_covered then v_subscription.id else null end
  )
  returning *;
end;
$$;

revoke all on function public.create_vip_booking(
  uuid, uuid, uuid, timestamptz, timestamptz, text
) from public;
grant execute on function public.create_vip_booking(
  uuid, uuid, uuid, timestamptz, timestamptz, text
) to authenticated;

commit;
