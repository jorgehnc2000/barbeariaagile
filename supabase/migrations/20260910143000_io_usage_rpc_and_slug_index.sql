-- RPC leve para contagem de uso VIP (evita SELECT de todas as linhas do mês).
create or replace function public.count_vip_monthly_usage(
  p_subscription_id uuid,
  p_barbershop_id uuid,
  p_period_start timestamptz,
  p_period_end timestamptz
)
returns integer
language sql
stable
security invoker
as $$
  select count(*)::integer
    from public.agendamentos a
   where a.subscription_id = p_subscription_id
     and a.barbershop_id = p_barbershop_id
     and a.covered_by_plan = true
     and a.data_inicio >= p_period_start
     and a.data_inicio < p_period_end
     and lower(coalesce(a.status, '')) not in (
       'cancelado', 'canceled', 'cancelled'
     );
$$;

grant execute on function public.count_vip_monthly_usage(uuid, uuid, timestamptz, timestamptz)
  to authenticated;

-- Lookup por slug (BarbershopResolver.refreshCurrent).
create index if not exists idx_barbershops_slug
  on public.barbershops (slug);

analyze public.barbershops;
