-- Benefício VIP (R$ 0,00) somente com status Mercado Pago 'authorized'.
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

  -- Somente assinatura autorizada libera cobertura VIP.
  select s.*
    into v_subscription
    from public.subscriptions s
   where s.user_id = v_user_id
     and s.barbershop_id = p_barbershop_id
     and lower(trim(s.status)) = 'authorized'
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
