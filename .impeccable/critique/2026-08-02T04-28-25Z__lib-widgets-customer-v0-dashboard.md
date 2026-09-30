---
target: client home v0 dashboard
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
timestamp: 2026-08-02T04-28-25Z
slug: lib-widgets-customer-v0-dashboard
---
# Critique: Client home v0 dashboard

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Loading/Error/VIP badges solid; hover on non-tappable stats |
| 2 | Match System / Real World | 3 | PT-BR barbershop OK; metric cards feel SaaS |
| 3 | User Control and Freedom | 3 | Clear nav exits; retries |
| 4 | Consistency and Standards | 2 | Radius 24 vs Soft Forge ~16; dual "próximo" |
| 5 | Error Prevention | 2 | VIP copy strong; false affordances on stats |
| 6 | Recognition Rather Than Recall | 3 | Labeled CTAs/status |
| 7 | Flexibility and Efficiency | 2 | Multi-path Agendar; no accelerators |
| 8 | Aesthetic and Minimalist Design | 2 | Vanity metrics + redundant next + marketing clutter |
| 9 | Error Recovery | 3 | Home/VIP retry in PT-BR |
| 10 | Help and Documentation | 1 | No contextual help; empty states thin |
| **Total** | | **24/40** | **Acceptable** |

## Design Specificity Verdict

**LLM:** Hybrid — Midnight Atelier palette, VIP status machine, and tenant hero photo feel authored; IA (greeting → 3 metrics → hero → side cards) is category dashboard / v0 SaaS. Vanity counts (Serviços/Barbeiros) conflict with DESIGN.md anti-reference against clinical metric cards. Brand on hero is a small gold pill, not a hero-level brand signal.

**Deterministic scan:** detect.mjs returned `[]` for Dart targets (`.dart` not in SCANNABLE_EXTENSIONS) and for Flutter `index.html` shell. Zero findings — not a clean pass, a non-applicable scan.

**Visual overlays:** Not available. Browser MCP could not hold a navigable tab; Flutter canvas cannot host HTML detect overlays. Live URLs return 200 Flutter bootstrap; authenticated home not inspected this run.

## Overall Impression

The home improved as a dark-luxury surface (hero + VIP + motion), but still reads as a metric hub before a booking ritual. Biggest opportunity: lead with tenant vitrine + one next/VIP decision, demote vanity stats and redundant Agendar paths.

## What's Working

1. VIP card: status → plain-language message → one gold action (esp. past-due/Regularizar).
2. Desktop composition hero ‖ VIP + next closest to "vitrine + scannable booking."
3. Motion with reduced-motion respect (`V0Motion`).

## Priority Issues

### [P1] Metric strip (Serviços/Barbeiros) owns early viewport
- **Why:** Clinical dashboard load; delays hero/booking; fights Midnight Atelier brief.
- **Fix:** Remove or bury; open with hero + next/VIP.
- **Suggested command:** `/impeccable distill` or `/impeccable layout`

### [P1] Redundant "próximo" + multiple Agendar CTAs
- **Why:** Choice overload; no single focus for "book now."
- **Fix:** One next-appointment surface; one primary book CTA; demote others.
- **Suggested command:** `/impeccable distill`

### [P1] Mobile stack: stats above hero; weak brand signal
- **Why:** First fold sells counts, not the house; brand as eyebrow pill.
- **Fix:** Hero (+ tenant brand) first; stats gone or tertiary.
- **Suggested command:** `/impeccable layout` / `/impeccable bolder`

### [P2] Gold saturation + radius drift (24 vs 16–18)
- **Why:** Dilutes One Gold Rule and Soft Forge.
- **Fix:** Gold for CTA + VIP urgency only; align radii to tokens.
- **Suggested command:** `/impeccable quieter` or `/impeccable polish`

### [P2] A11y / affordance gaps
- **Why:** Hover polish on non-interactive stats; missing semantics on images.
- **Fix:** Semantics; hover only on actionable controls.
- **Suggested command:** `/impeccable audit` / `/impeccable harden`

### Adjacent [P0 journey] Auth gate
Anonymous users never see home vitrine — login first. Note for product, not only home widgets.

## Persona Red Flags

**Jordan (first-timer):** Login before any shop ritual; vanity metrics don't answer how to book; Agenda vs Agendar in 5-tab nav confuses.

**VIP past-due:** Home VIP messaging is a strength; competing gold "Agendar agora" can undercut Regularizar urgency.

**Casey (mobile one-hand):** Primary book CTA mid-scroll after stats; dense stack increases mis-taps.

## Minor Observations

- Fallback brand `"Barbearia Moura's"` feels hard-coded.
- Empty next-stat shows `—` trophy.
- Non-VIP `BarbeariaSpotlightCard` flatter than `V0VipClubCard` (dual languages).

## Questions to Consider

1. If the job is book in one glance, why do service/barber counts earn the first viewport?
2. Should logged-out users see a tenant vitrine with auth only at confirm?
3. What if VIP past-due or next appointment became the single composition?
