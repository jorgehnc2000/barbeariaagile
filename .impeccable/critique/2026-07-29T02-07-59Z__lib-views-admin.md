---
target: paginas do admin
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 3
timestamp: 2026-07-29T02-07-59Z
slug: lib-views-admin
---
# Critique — lib/views/admin

Method: dual-agent (A: de6a50a6-c2bb-4b89-819f-a3e10db847cc · B: b35ebf38-b9be-4f53-97d9-499bf6f73df4)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Silent validation on barbeiro/serviço forms |
| 2 | Match System / Real World | 3 | Strong PT copy; leaks MRR / Foto URL / Configurações MP |
| 3 | User Control and Freedom | 3 | No undo after delete / VIP toggle |
| 4 | Consistency and Standards | 2 | AgendaElite glass vs flat Operate; VIP header mismatch |
| 5 | Error Prevention | 2 | Dead contact buttons; silent invalid save |
| 6 | Recognition Rather Than Recall | 3 | Collapsed icon-only sidebar; VIP split across pages |
| 7 | Flexibility and Efficiency | 1 | No shortcuts, bulk actions, or saved filters |
| 8 | Aesthetic and Minimalist Design | 2 | Elite glow + Relatórios + VIP dialog compete |
| 9 | Error Recovery | 2 | Raw Erro: $e on CRUD; silent validation |
| 10 | Help and Documentation | 1 | Almost no contextual help |
| **Total** | | **22/40** | **Acceptable** |

## Design Specificity Verdict

**LLM:** Partially authored — strong Portuguese day-ops voice and tenant branding, but fractured by AgendaElite (glass/glow) vs Midnight Atelier Operate elsewhere. CRUD grids remain category-interchangeable.

**Deterministic scan:** detect.mjs exit 0, 0 findings on lib/views/admin. No overlays (browser tab lifecycle failed before injection). Not reported as visually clean — browser path unavailable.

## Overall Impression

Dashboard and Operate kit carry Midnight Atelier well. AgendaElite desktop is a second visual product. Biggest opportunity: one visual world + fix false contact affordances + honest form validation.

## What's Working

1. DashboardPage day-ops framing (Hoje na casa, timeline, next client)
2. Shared Operate kit (AdminPageHeader, surfaces, forge radii)
3. Agenda IA by barbeiro + Manhã/Tarde/Noite

## Priority Issues

### [P0] Dead contact buttons in booking details
- What: phone/mail _ContactButton onTap empty
- Why: false affordance mid-service
- Fix: wire tel:/mailto: or remove until real
- Suggested command: /impeccable harden

### [P1] AgendaElite vs Midnight Atelier fracture
- What: glass/glow/ALL-CAPS chips vs flat OperateVisuals
- Why: two admin products; breaks One Gold Rule
- Fix: rebase elite on Operate tokens; gold only for status/CTA
- Suggested command: /impeccable quieter or /impeccable polish

### [P1] Silent validation on Equipe/Serviços forms
- What: empty name/price returns without message
- Why: Salvar feels broken
- Fix: inline validators + snackbar
- Suggested command: /impeccable harden

### [P1] A11y gaps on elite controls + sidebar
- What: GestureDetector day/chips; no Semantics; icon-only collapsed nav
- Why: blocks keyboard/SR users
- Fix: InkWell+focus, Semantics, tooltips when compact
- Suggested command: /impeccable audit

### [P2] Mobile bottom nav buries Barbeiros/Serviços/Relatórios
- What: Menu dumps full IA; VIP/Casa swap
- Why: busy operator loses team/catalog
- Fix: promote Agenda+Equipe; stable labels
- Suggested command: /impeccable adapt

## Persona Red Flags

**Alex:** no shortcuts/batch; long VIP dialog; collapsed sidebar slows scan
**Sam:** GestureDetector elite controls; muted #777 on #1E1E1E contrast risk; unlabeled icon contacts
**Operador Moura:** dead call/email mid-rush; mobile hides Serviços/Barbeiros; elite density hurts glanceability

## Minor Observations

- ClubeVipConfigPage uses ScreenHeaderBar vs AdminPageHeader
- RelatoriosPage month-only, no range
- AgendaElite more_horiz implies missing menu
- Empty states thinner on Equipe/Serviços than VIP/dashboard

## Questions to Consider

1. Which world owns Midnight Atelier — Operate shell or AgendaElite?
2. What is the one rush-hour admin job — and why seven equal nav destinations?
3. Prefer thumb-first Agenda over glass columns board?
4. Is VIP three-tabs+kill-switch for the busy dono or a SaaS power admin?
