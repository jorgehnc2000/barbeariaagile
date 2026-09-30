# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Dois públicos com peso equivalente:

- **Cliente:** agenda serviços, acompanha a agenda e usa o Clube VIP (quando elegível).
- **Admin (dono/operador da barbearia):** gerencia a operação completa — agenda, barbeiros, serviços, dados da loja, Clube VIP e integração Mercado Pago.

O barbeiro é recurso gerenciado pelo admin (listado no agendamento), não um papel de login confirmado.

## Product Purpose

Aplicação web multi-tenant para barbearias: cada loja opera sob seu próprio slug na URL, com app do cliente e painel admin. Existe para digitalizar o ritual de agendar e a operação da loja (catálogo, equipe, agenda, assinaturas VIP e cobrança).

Sucesso = o cliente consegue agendar com clareza; o admin controla a loja e a cobrança VIP sem sair do painel.

## Positioning

Sistema de gestão de barbearia multi-tenant por slug, com gestão operacional completa **incluindo** a integração Mercado Pago (planos VIP, assinaturas e credenciais por tenant) — não apenas agenda isolada.

## Operating Context

- Acesso por URL com slug do tenant (`/{slug}`, `/{slug}/admin/...`).
- Cliente: autenticação, Início, Agendar, Agenda, Clube VIP, Perfil.
- Admin: Dashboard, Agenda Online, Barbeiros, Serviços, Barbearia, Clube VIP, Relatórios.
- Cobrança VIP via Mercado Pago (preapproval / planos); status de assinatura afeta benefício no agendamento.
- Deploy web (ex.: Vercel); backend Supabase (dados + Edge Functions).

## Capabilities and Constraints

**Confirmado**

- Multi-tenant por `barbershop` / slug; dados e MP são por tenant.
- Flutter web responsivo (mobile e desktop).
- Papéis: `cliente` e `admin`.
- Agendamento com serviços, barbeiros e horários.
- Clube VIP: planos, assinantes, sync/cancelamento Mercado Pago; benefício R$ 0,00 só com assinatura `authorized`.
- UI e copy em português (PT-BR).

**Restrição explícita (trabalho futuro)**

- O **multi-tenant** deve ser preservado: nenhum fluxo ou tela pode misturar ou ignorar o tenant ativo.

**Em aberto**

- Expansão nativa (iOS/Android) não é requisito atual.
- Branding visual formal além do tema já no código não foi fixado neste init (apenas multi-tenant como regra dura).

## Brand Commitments

- Produto/tenant de referência no código: **Barbearia Moura** (`MaterialApp` title); nome da loja vem do tenant (`nome`).
- Interface e terminologia em português: Início, Agendar, Agenda, Clube VIP, Painel Admin, etc.
- Nenhum manual de marca externo foi vinculado neste init.

## Evidence on Hand

- Código Flutter: `lib/` (cliente, admin, tema, resolver de tenant).
- Backend: `supabase/` (migrations + Edge Functions MP).
- Deploy de referência no código: `https://barbeariaagile.vercel.app/{slug}`.
- Sem `PRODUCT.md`/`DESIGN.md` anteriores; README é template Flutter.
- Não inventar depoimentos, pricing público, benchmarks ou cases sem evidência.

## Product Principles

1. **Tenant first** — toda decisão de produto e UI respeita o isolamento por barbearia/slug.
2. **Dois lados, um produto** — cliente e admin têm o mesmo peso; nenhum fluxo pode quebrar o outro.
3. **Operação completa** — o admin gerencia a loja e a cobrança VIP (Mercado Pago) no mesmo sistema.
4. **Web responsivo** — experiências usáveis em celular e desktop sem depender de app nativo.
5. **Não fabricar prova** — conteúdo, métricas e claims só com evidência real no produto ou fornecida pelo time.
