-- Corrige gate de entitlement: somente 'approved' libera VIP; demais estados bloqueiam.

create or replace function public.get_vip_entitlement_status(
  p_user_id uuid,
  p_barbershop_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_sub public.subscriptions%rowtype;
  v_preapproval text;
  v_payment text;
begin
  if p_user_id is null or p_barbershop_id is null then
    return 'INACTIVE';
  end if;

  select *
    into v_sub
    from public.subscriptions s
   where s.user_id = p_user_id
     and s.barbershop_id = p_barbershop_id
   limit 1;

  if not found then
    return 'INACTIVE';
  end if;

  v_preapproval := lower(trim(coalesce(v_sub.status, '')));
  v_payment := lower(trim(coalesce(v_sub.last_payment_status, '')));

  if v_preapproval in ('canceled', 'cancelled', 'cancelado', 'expired') then
    return 'INACTIVE';
  end if;

  if v_preapproval <> 'authorized' then
    return 'INACTIVE';
  end if;

  if v_payment = 'approved' then
    return 'ACTIVE';
  end if;

  if v_payment in ('rejected', 'cancelled', 'canceled', 'in_process') then
    return 'PAST_DUE';
  end if;

  -- Legado sem sincronização de pagamento: mantém benefício até o primeiro sync.
  if v_payment = '' or v_payment is null then
    return 'ACTIVE';
  end if;

  -- scheduled, processed, pending etc. — preapproval ativo sem cobrança aprovada.
  return 'PAST_DUE';
end;
$$;
