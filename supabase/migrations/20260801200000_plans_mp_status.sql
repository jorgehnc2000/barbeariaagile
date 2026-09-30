-- Status explícito da integração Mercado Pago por plano.
-- pending = ainda não sincronizado; synchronized = pronto para venda no app cliente.

alter table public.plans
  add column if not exists mp_status text;

comment on column public.plans.mp_status is
  'pending | synchronized — integração do plano com Mercado Pago.';

update public.plans
   set mp_status = case
     when nullif(trim(mp_plan_id), '') is not null then 'synchronized'
     else 'pending'
   end
 where mp_status is null
    or trim(mp_status) = '';

alter table public.plans
  alter column mp_status set default 'pending',
  alter column mp_status set not null;

alter table public.plans
  drop constraint if exists plans_mp_status_check;

alter table public.plans
  add constraint plans_mp_status_check
  check (mp_status in ('pending', 'synchronized'));

-- Plano com MP pendente não pode ficar "ativo" para venda.
update public.plans
   set active = false
 where mp_status = 'pending'
   and active = true;

create index if not exists plans_barbershop_client_ready_idx
  on public.plans (barbershop_id, active, mp_status)
  where active = true and mp_status = 'synchronized';
