---
name: Barbearia App
description: Midnight Atelier — dark-luxury multi-tenant barbershop UI (Flutter web)
colors:
  ouro-de-atelier: "#D4AF37"
  ouro-brilho: "#FFB300"
  ouro-profundo: "#B8962E"
  carvao-meia-noite: "#121212"
  mesa-escura: "#1E1E1E"
  borda-forja: "#2A2A2A"
  cinza-bancada: "#3A3A3A"
  texto-luz: "#FFFFFF"
  texto-nevoa: "#999999"
  texto-sombra: "#777777"
  sucesso: "#4CAF50"
  erro: "#E53935"
typography:
  display:
    fontFamily: "Sora, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Sora, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  title:
    fontFamily: "Sora, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "normal"
  title-ui:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "normal"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "normal"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
rounded:
  sm: "10px"
  md: "14px"
  lg: "16px"
  xl: "18px"
  pill: "20px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "28px"
  page-mobile: "20px"
  page-desktop: "32px"
components:
  button-primary:
    backgroundColor: "{colors.ouro-de-atelier}"
    textColor: "{colors.carvao-meia-noite}"
    rounded: "{rounded.md}"
    height: "52px"
    padding: "0 24px"
    typography: "{typography.label}"
  button-primary-disabled:
    backgroundColor: "#D4AF3759"
    textColor: "{colors.carvao-meia-noite}"
    rounded: "{rounded.md}"
    height: "52px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.texto-luz}"
    rounded: "{rounded.md}"
    height: "52px"
  card-surface:
    backgroundColor: "{colors.mesa-escura}"
    textColor: "{colors.texto-luz}"
    rounded: "{rounded.lg}"
    padding: "16px"
  input-field:
    backgroundColor: "{colors.mesa-escura}"
    textColor: "{colors.texto-luz}"
    rounded: "{rounded.md}"
    padding: "16px"
  chip-time-selected:
    backgroundColor: "{colors.ouro-de-atelier}"
    textColor: "{colors.carvao-meia-noite}"
    rounded: "{rounded.md}"
  chip-time-idle:
    backgroundColor: "transparent"
    textColor: "{colors.ouro-brilho}"
    rounded: "{rounded.md}"
  nav-bottom-glass:
    backgroundColor: "#E61E1E1E"
    textColor: "{colors.texto-luz}"
    rounded: "{rounded.xl}"
---

# Design System: Barbearia App

## Overview

**Creative North Star: "The Midnight Atelier"**

Uma oficina noturna de barbearia premium: carvão profundo, ouro de atelier e tipografia limpa. O produto é multi-tenant e Operate (agendar, VIP, painel), mas a presença visual é de **vitrine dark-luxury** — hero, Clube VIP e CTAs de ouro carregam a atmosfera; a operação permanece escaneável por baixo.

A densidade é generosa nos cantos e nos cards (vitrine tátil), sem cair em glassmorphism genérico nem em dashboard clínico. O ouro é raro e deliberado: ilumina ação, status VIP e ênfase — não decora tudo.

**Anti-referências confirmadas:** SaaS roxo / glassmorphism genérico; template “barbearia Instagram” com serif cream; dashboard branco clínico com cards de métrica.

**Key Characteristics:**
- Dark-first (`#121212` → `#1E1E1E`) com ouro `#D4AF37` como voz única de acento
- Sora (display/títulos) + Inter (UI/corpo)
- Cantos generosos (14–18px); botões altos (52px)
- Profundidade híbrida: camadas tonais + sombra suave só em hero/VIP/CTA
- Multi-tenant: a marca da loja personaliza o chrome, o sistema visual permanece

## Colors

Paleta noturna de atelier: carvão, mesa escura e um único metal — ouro.

### Primary
- **Ouro de Atelier** (`#D4AF37`): acento de marca — botões filled, bordas ativas, ícones de ênfase, indicadores de nav selecionada.
- **Ouro Brilho** (`#FFB300`): highlight / secondary do scheme — texto de preço VIP, foco luminoso.
- **Ouro Profundo** (`#B8962E`): extremo escuro do gradient de CTA.

### Neutral
- **Carvão de Meia-Noite** (`#121212`): scaffold / fundo de página.
- **Mesa Escura** (`#1E1E1E`): cards, sheets, surfaces elevadas, inputs filled.
- **Borda Forja** (`#2A2A2A`): divisores e contornos quietos de card.
- **Cinza Bancada** (`#3A3A3A`): surface light / chips muted.
- **Texto Luz** (`#FFFFFF`): títulos e UI principal.
- **Texto Névoa** (`#999999`): corpo secundário.
- **Texto Sombra** (`#777777`): hints, labels muted, slots passados.

### Semantic
- **Sucesso** (`#4CAF50`): VIP ativo / disponível.
- **Erro** (`#E53935`): destructivo, falhas.

### Named Rules
**The One Gold Rule.** O ouro de atelier aparece em ≤ ~10–15% da tela — CTAs, status VIP, seleção. Se tudo brilhar, nada brilha.

**The No Purple SaaS Rule.** Sem gradientes índigo/roxo, glow neon ou glass decorativo como identidade.

## Typography

**Display Font:** Sora (com system-ui)
**Body Font:** Inter (com system-ui)

**Character:** Sora carrega o ritual (títulos, hero, headers de sheet); Inter conduz a operação (listas, forms, labels). Sem serif cream.

### Hierarchy
- **Display** (Sora 700, 32px, tracking −0.5): hero / saudações fortes.
- **Headline** (Sora 700, 22px): títulos de sheet e seções (“Agendar”).
- **Title** (Sora 700, 18px): headers de painel / section.
- **Title UI** (Inter 600, 16px): subtítulos de tarefa.
- **Body** (Inter 400, 14–16px): copy operacional e secondary text.
- **Label** (Inter 700, 14px / nav 12px): botões e bottom nav.

### Named Rules
**The Two-Voice Rule.** Sora fala marca e hierarchy; Inter fala tarefa. Não inverter.

## Layout

Modelo Operate responsivo com vitrine no primeiro viewport do cliente.

- **Cliente max width:** 1120px · **Admin:** 1280px · **Forms:** 560px
- **Breakpoints:** compact &lt; 700px · client desktop ≥ 900px
- **Page padding:** mobile ~20px · desktop ~32px (admin 16/28)
- **Bottom inset mobile:** ~110px sob floating nav
- **Rhythm:** grupos internos 12–16px; seções 24–28px
- **Cliente Início:** hero + VIP como composição de vitrine; catálogo como convite secundário
- **Booking sheet:** dia → horários por Manhã/Tarde/Noite → valor → confirmar

### Named Rules
**The Tenant Frame Rule.** Largura e padding são do sistema; nome/foto/logo vêm do tenant — nunca misturar dados entre barbearias.

## Elevation & Depth

**Híbrido:** profundidade principalmente tonal (carvão → mesa escura → borda), com **sombra suave só** em momentos de vitrine — hero, Clube VIP, CTAs de ouro / botões com presença.

Cards e inputs em repouso: flat + border (`#2A2A2A` / surfaceLight alpha). Glass da bottom nav usa fill escuro semi-opaco + borda ouro suave — utilitário de flutuação, não identidade glassmorphism.

### Named Rules
**The Shadow-as-Spotlight Rule.** Sombra não empilha cards; ilumina o que a vitrine quer vender (VIP, hero, ação primária).

## Shapes

Forma **vitrine tátil**: cantos generosos e consistentes.

- **Controles / inputs / botões:** ~14px
- **Cards / sheets top:** ~16–18px
- **Chips / badges:** ~10–14px; pills de status ~20px
- **Handle de bottom sheet:** pill curto 40×4
- **Bordas:** 1–1.5px; seleção de slot com stroke ouro

### Named Rules
**The Soft Forge Rule.** Prefira 14–18px a pills full-round em containers grandes; full-round só em badges/chips pequenos.

**The Admin Dual-Skin Rule.** No painel admin, o breakpoint ≥900px usa **AgendaElite** (glass, Ink Edge, headers Elite). Abaixo disso, o painel volta ao **Midnight Atelier / Operate** (superfícies flat `#1E1E1E`, CTA ouro filled). Não misturar skins no mesmo viewport — badges, toggles, ghosts e CTAs passam por wrappers `Admin*` que escolhem Elite vs Atelier. O app do cliente permanece sempre Midnight Atelier.

**Admin mobile nav.** Bottom bar: Início · Agenda · Operações · Mais. Operações abre sheet com Equipe e Serviços (acesso diário sem drawer). Mais abre o drawer (Barbearia, VIP, Relatórios, Sair).

## Components

Caráter geral: **vitrine tátil** — presença clara, ouro nos primários, secundários contidos.

### Buttons
- **Shape:** Soft Forge ~14px; altura mínima 48–52px com padding horizontal generoso (nunca texto colado)
- **Primary (cliente / admin mobile):** fundo Ouro de Atelier, texto carvão; disabled = ouro ~35% alpha
- **Primary (admin desktop):** Ink Edge — outline/fill ouro suave, texto ouro (One Gold Rule)
- **Outlined / ghost:** stroke quieto ou texto; destructive em vermelho sem competir com o CTA
- **Text / Trocar:** ouro ou primary como ink, sem caixa

### Chips (time slots / status)
- **Idle:** stroke ouro, texto ouro brilho, fundo transparente
- **Selected:** fill ouro, texto carvão
- **Unavailable:** muted, sem interação
- **VIP / status badges:** pill com fill tintado success/ouro/erro

### Cards / Containers
- **Corner:** 16–18px
- **Background:** Mesa Escura
- **Border:** Borda Forja (ou ouro alpha em VIP)
- **Padding:** 16–20px
- **VIP card:** gradient carvão quente + border ouro alpha

### Inputs / Fields
- **Filled** Mesa Escura, radius 14, padding 16
- **Focus:** border ouro 1.5px
- **Hint:** Texto Sombra

### Navigation
- **Desktop top:** links Sora/Inter; ativo em ouro
- **Mobile bottom:** glass floating (fill `#E61E1E1E`), ícone+label 12px; selecionado ouro
- **Admin:** shell próprio; mesmos tokens de cor/tipo

### Signature — Booking sheet
Sheet 85vh max, handle, header com serviço/barbeiro + Trocar, DayTimeline, slots por período, resumo VIP, confirmar + cancelar. Auth gate antes de abrir se deslogado.

## Do's and Don'ts

### Do:
- **Do** tratar o ouro como voz rara (One Gold Rule).
- **Do** usar Sora para hierarchy e Inter para tarefa.
- **Do** manter dark-first e personalizar só com assets do tenant.
- **Do** agrupar horários em Manhã / Tarde / Noite no booking.
- **Do** elevar VIP e hero como momentos de vitrine (sombra/híbrido permitido).

### Don't:
- **Don't** introduzir roxo, indigo SaaS ou glow neon como identidade.
- **Don't** usar serif cream / terracotta “barbearia Instagram”.
- **Don't** virar dashboard branco clínico com cards de métrica genéricos.
- **Don't** aplicar glassmorphism decorativo em toda superfície.
- **Don't** inventar prova social, pricing ou cases fora do PRODUCT.md.
