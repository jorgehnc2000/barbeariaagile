-- Otimização de I/O: índices B-Tree alinhados às consultas do app Flutter.
-- Tabelas reais: agendamentos (não appointments), cliente_id (não user_id), data_inicio (não date).

-- ---------------------------------------------------------------------------
-- agendamentos — listagens admin, agenda do cliente, slots ocupados, VIP usage
-- ---------------------------------------------------------------------------

-- Agenda admin por dia + relatórios mensais (barbershop_id + intervalo de data)
create index if not exists idx_agendamentos_barbershop_data_inicio
  on public.agendamentos (barbershop_id, data_inicio);

-- Filtro frequente: tenant + status + data (dashboard / agenda sem cancelados)
create index if not exists idx_agendamentos_barbershop_status_data
  on public.agendamentos (barbershop_id, status, data_inicio);

-- Agenda do cliente (cliente_id + tenant, ordenado por data)
create index if not exists idx_agendamentos_cliente_barbershop_data
  on public.agendamentos (cliente_id, barbershop_id, data_inicio desc);

-- Slots ocupados por barbeiro/dia (fetchOccupiedSlots)
create index if not exists idx_agendamentos_barbeiro_barbershop_data
  on public.agendamentos (barbeiro_id, barbershop_id, data_inicio);

-- Uso mensal VIP (subscription_id + mês + covered_by_plan)
-- Complementa agendamentos_subscription_month_idx existente.
create index if not exists idx_agendamentos_subscription_covered_data
  on public.agendamentos (subscription_id, data_inicio)
  where subscription_id is not null and covered_by_plan = true;

-- ---------------------------------------------------------------------------
-- users — listagens por tenant e lookup de perfil
-- ---------------------------------------------------------------------------

create index if not exists idx_users_barbershop_id
  on public.users (barbershop_id);

do $$
begin
  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'users'
       and column_name = 'email'
  ) then
    execute $sql$
      create index if not exists idx_users_barbershop_email
        on public.users (barbershop_id, email)
        where email is not null
    $sql$;
  end if;

  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'users'
       and column_name = 'telefone'
  ) then
    execute $sql$
      create index if not exists idx_users_barbershop_telefone
        on public.users (barbershop_id, telefone)
        where telefone is not null
    $sql$;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- barbeiros — catálogo e contagem de ativos no dashboard
-- ---------------------------------------------------------------------------

create index if not exists idx_barbeiros_barbershop_disponivel
  on public.barbeiros (barbershop_id, disponivel);

-- ---------------------------------------------------------------------------
-- subscriptions — já existem subscriptions_user_barbershop_uidx e
-- subscriptions_barbershop_status_idx; reforço por user_id + status (app cliente)
-- ---------------------------------------------------------------------------

create index if not exists idx_subscriptions_user_status
  on public.subscriptions (user_id, status);

-- ---------------------------------------------------------------------------
-- barbearia_info — lookup singleton por tenant
-- ---------------------------------------------------------------------------

create index if not exists idx_barbearia_info_barbershop_id
  on public.barbearia_info (barbershop_id);

-- ---------------------------------------------------------------------------
-- servicos / plans — listagens por tenant (baixo volume, mas evita seq scan)
-- ---------------------------------------------------------------------------

create index if not exists idx_servicos_barbershop_nome
  on public.servicos (barbershop_id, nome);

-- plans_barbershop_active_idx e plans_barbershop_client_ready_idx já existem.

-- Atualiza estatísticas para o planner usar os novos índices imediatamente.
analyze public.agendamentos;
analyze public.users;
analyze public.barbeiros;
analyze public.subscriptions;
