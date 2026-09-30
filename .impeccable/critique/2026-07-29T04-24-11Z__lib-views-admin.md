---
target: admin
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 3
timestamp: 2026-07-29T04-24-11Z
slug: lib-views-admin
---
⚠️ DEGRADED: single-context (sub-agents unavailable — API limit)

# Critique — Admin panel (`lib/views/admin`)

**Mode:** Operate · **Slug:** `lib-views-admin`

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Loading/snackbars existem; validação de form ainda pode falhar em silêncio |
| 2 | Match System / Real World | 3 | PT-BR e vocabulário de casa (Equipe, A casa, fila) |
| 3 | User Control and Freedom | 3 | Cancelar/dialogs/logout claros |
| 4 | Consistency and Standards | 2 | Dual-skin Elite/Atelier + Clube VIP ainda mais denso que Equipe/Serviços |
| 5 | Error Prevention | 2 | `return` silencioso em nome/preço vazios nos forms admin |
| 6 | Recognition Rather Than Recall | 3 | Nav rotulada; badges Ativo/Inativo + toggle |
| 7 | Flexibility and Efficiency | 2 | Poucos atalhos; colunas só na Agenda desktop |
| 8 | Aesthetic and Minimalist Design | 3 | Soft Forge + Ink Edge desktop melhoraram ouro raro; glass Elite ainda denso |
| 9 | Error Recovery | 2 | Snackbars com `Erro: $e` técnicos; Acesso Negado ok com CTA |
| 10 | Help and Documentation | 2 | Empty states no VIP ajudam; sem ajuda contextual no resto |
| **Total** | | **25/40** | **Needs work** |

## Design Specificity Verdict

**LLM:** O painel já não é um dashboard SaaS genérico. Midnight Atelier no mobile + Elite glass/Ink Edge no desktop (≥900) é uma decisão de produto clara para Operate. Soft Forge (14px), CTAs responsivos e cards densos de Equipe/Serviços carregam identidade de barbearia premium. Ainda há fratura: Clube VIP e alguns dialogs não falam o mesmo dialeto; copy/mojibake e validação silenciosa quebram o craft operacional.

**Deterministic scan:** `detect.mjs` em `design/` → **89 findings** (sobre HTML de preview, não o Flutter runtime). Top: `design-system-font-size` (67), `design-system-font` (8), `overused-font` Inter (6), `dark-glow` (3). Em grande parte **falso positivo** para o app: Inter/Sora estão no DESIGN.md; o scan leu previews Tailwind, não `lib/views/admin`.

**Visual overlays:** Injection `detect.js` **não aplicável** — superfície Flutter canvas (`flutter-view`). Browser: `/barbeariamoura/admin` mostrou estado **Acesso Negado** (slug inválido) com card escuro + CTA Ink Edge “Ir para o login” — confirma o sistema de botões, mas não o shell autenticado.

## Overall Impression

O admin amadureceu: dual-skin e botões deixaram de parecer Material genérico. O maior risco agora não é “feio” — é **inconsistência entre telas** e **falhas silenciosas** que o operador não vê.

## What's Working

1. **Dual-skin consciente** (`AdminVisuals.isElite`) — Elite no desktop, Atelier flat no mobile, sem misturar cliente.
2. **Vocabulário Soft Forge** — Ink Edge no desktop, ouro filled no mobile, ghost/outline/danger no kit.
3. **Equipe/Serviços densos** — badge + toggle; lista de serviço escaneável (~64px).

## Priority Issues

### [P0] Validação silenciosa nos forms
- **What:** Em Equipe/Serviços, `onSave` faz `return` se nome/preço inválidos — sem SnackBar/inline error.
- **Why:** Operador acha que o botão está quebrado.
- **Fix:** Mensagem inline ou SnackBar “Informe o nome” / “Preço inválido”; disable Salvar até válido.
- **Suggested command:** `/impeccable harden admin forms` + `/impeccable clarify`

### [P1] Mojibake na Agenda
- **What:** Subtitle com `Â·` em `agenda_online_page.dart`.
- **Why:** Quebra confiança visual no coração da operação.
- **Fix:** Substituir por `·` UTF-8 correto.
- **Suggested command:** `/impeccable polish` (quick fix)

### [P1] Fratura de consistência (VIP vs Equipe + dual-skin)
- **What:** Clube VIP ainda mais “SaaS denso”; breakpoint 900px troca o mundo inteiro de uma vez.
- **Why:** Mesmo operador sente dois produtos; tablet fica no Elite sem querer.
- **Fix:** Alinhar VIP ao kit Soft Forge; documentar dual-skin no DESIGN.md; considerar corte por `shortestSide` se Elite for só “PC”.
- **Suggested command:** `/impeccable distill` (VIP) + `/impeccable document`

### [P1] Recuperação de erro técnica
- **What:** SnackBars `Erro: $e` e Acesso Negado sem marca/slug sugerido.
- **Why:** Dono de loja não debugga Exception; tenant errado precisa caminho óbvio.
- **Fix:** Copy humana + ação (tentar de novo / escolher loja); brand mark no empty/error.
- **Suggested command:** `/impeccable clarify` + `/impeccable harden`

### [P2] Carga cognitiva na navegação mobile
- **What:** Drawer + bottom bar + ~7 destinos (VIP condicional).
- **Why:** Operador no celular entre clientes precisa de 1–2 toques para Agenda/Equipe, não explorar menu.
- **Fix:** Priorizar Agenda/Dashboard no bottom; secundários só no drawer.
- **Suggested command:** `/impeccable distill` / `/impeccable adapt`

## Persona Red Flags

**Alex (power operator):** Sem atalhos; form Salvar silencioso; Agenda com encoding quebrado na subtítulo — atrito diário.

**Jordan (first-time shop owner):** Clube VIP + MP parece outro app; erros técnicos; Acesso Negado sem explicar slug.

**Dono multi-tenant (PRODUCT):** Precisa confiar no isolamento por slug — tela de Acesso Negado não educa sobre URL/`/{slug}/admin`.

## Minor Observations

- Empty “Nenhum barbeiro/serviço” são texto puro — poderiam onboardar.
- Desktop glass em toda superfície compete com One Gold Rule.
- `showAdminForm` desktop dialog vs sheet mobile: ok, mas Salvar deveria sempre `AdminPrimaryButton` (já encaminhado).
- Detector Inter: ignorar — está no DESIGN.md.

## Questions to Consider

- O dual-skin deve ser documentado como regra dura no DESIGN.md ou é experimento?
- Agenda é o “lar” do admin — o que sobra se Dashboard virar só um resumo da Agenda?
- Clube VIP precisa parecer painel financeiro ou oficina da casa?
