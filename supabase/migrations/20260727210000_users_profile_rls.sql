-- Permite que usuários autenticados criem e gerenciem o próprio perfil em public.users.

alter table public.users enable row level security;

drop policy if exists "Usuário lê próprio perfil" on public.users;
create policy "Usuário lê próprio perfil"
  on public.users
  for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "Usuário atualiza próprio perfil" on public.users;
create policy "Usuário atualiza próprio perfil"
  on public.users
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Usuário insere próprio perfil" on public.users;
create policy "Usuário insere próprio perfil"
  on public.users
  for insert
  to authenticated
  with check (auth.uid() = id);
