---
target: admin
total_score: 27
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
timestamp: 2026-07-29T04-45-55Z
slug: lib-views-admin
---
Method: dual-agent (A: f15a9492-02c8-48ee-8ac9-3fc6f14e17a5 · B: 25514b3d-88c4-4da5-b3b0-838362281b85)

# Critique — Admin panel (`lib/views/admin`) — re-run

**Mode:** Operate · Dual-Skin documentado · Soft Forge

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Validação SnackBar ok; VIP/toggle ainda paths mistos |
| 2 | Match System / Real World | 3 | `adminOpError` humano; “Foto URL” ainda técnico |
| 3 | User Control and Freedom | 3 | Confirma exclusão; mobile enterra Equipe no drawer |
| 4 | Consistency and Standards | 2 | Três caminhos de feedback; VIP denso vs Equipe Soft Forge |
| 5 | Error Prevention | 3 | Forms Equipe/Serviços validam; toggle sem undo |
| 6 | Recognition Rather Than Recall | 2 | Mobile: Equipe/Serviços só no Menu |
| 7 | Flexibility and Efficiency | 3 | Agenda colunas/chips; VIP sem busca assinantes |
| 8 | Aesthetic and Minimalist Design | 3 | Soft Forge ok; cards VIP ainda pesados |
| 9 | Error Recovery | 3 | `adminOpError` + Acesso Negado com slug; VIP ainda pode vazar Exception |
| 10 | Help and Documentation | 2 | MP tem copy; sem onboarding admin |
| **Total** | | **27/40** | **Needs work → improving** |

## Design Specificity Verdict

**LLM (A):** Midnight Atelier Operate + Dual-Skin Elite/Atelier é POV de produto, não SaaS genérico. Harden de validação/erros fechou o P0 anterior. Falta coesão VIP + IA mobile.

**Detector (B):** 89 findings só em `design/*_preview.html` — **não** no Flutter runtime. Inter/type-ramp = FP para o app. Overlay `detect.js` **skipped** (Flutter Web canvas).

**Browser (B):** `barbeariaagile.vercel.app` HTTP 200, título Barbearia Moura, `flutter-view`. Admin autenticado não verificado.

## Overall Impression

**22 → 25 → 27.** O painel ganhou confiança operacional (forms/erros). O próximo salto é **onde o operador toca todo dia no celular** (nav) e **VIP sem parecer outro produto**.

## What's Working

1. Dual-Skin codificado + regra no DESIGN.md  
2. `showAdminSnack` / `adminOpError` nos CRUD Equipe/Serviços  
3. Agenda subtitle limpo; Soft Forge / Ink Edge  

## Priority Issues

### [P0] Nav mobile esconde Equipe/Serviços
- **Why:** Operação diária exige drawer  
- **Fix:** Bottom bar com Operações (Equipe+Serviços) ou 5º slot Mais  
- **Command:** `/impeccable adapt` admin mobile nav  

### [P1] Feedback ainda fragmentado
- **Why:** VIP/`_showMessage` e toggle Equipe fora do kit  
- **Fix:** Tudo via `showAdminSnack` + `adminOpError`  
- **Command:** `/impeccable harden` + `/impeccable clarify`  

### [P1] Forms Equipe/Serviços sem `adminInputDecoration`
- **Why:** Inputs Material crus vs DESIGN.md  
- **Fix:** Aplicar `adminInputDecoration` nos fields  
- **Command:** `/impeccable polish` / `typeset`  

### [P2] Leak Elite* no mobile
- **Why:** Badge/ghost/toggle Elite em viewport Atelier  
- **Fix:** Wrappers Admin com `isElite`  
- **Command:** `/impeccable distill` dual-skin  

### [P2] Cards VIP densos + sombra
- **Why:** Quebra One Gold / Shadow-as-Spotlight  
- **Fix:** Flatten surfaces; 1 CTA primário por card  
- **Command:** `/impeccable quieter` / `distill` VIP  

## Persona Red Flags

- **Alex (celular):** Agenda ok; cadastrar barbeiro = fricção no drawer  
- **Jordan (desktop):** Elite premium; inputs crus + VIP pesado  
- **Dono multi-tenant:** Acesso Negado melhor; Exception no MP ainda mina confiança  

## Minor Observations

- Contact buttons na agenda com `onTap` vazio  
- Dashboard error ainda genérico  
- Toolbar Agenda alinhamento  

## Questions to Consider

- VIP é setup raro ou checagem diária?  
- Sem VIP, o slot inferior vira hub de Operações?  
- Elite* abaixo de 900px deve ser proibido?
