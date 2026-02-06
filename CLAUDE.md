# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FuckCorpo** is a satirical web application that calculates and tracks money earned during bathroom breaks at work. It uses a "Capitalist Satire" aesthetic — appropriating Wall Street/corporate visual language to celebrate worker autonomy. Think *The Onion* meets *Wall Street Journal*.

**Current status**: Design specification phase (pre-development). No source code, build system, or dependencies exist yet. The repository contains two specification documents that define what needs to be built.

## Specification Documents

- **fuckcorpo-design-system.md** — Complete visual design system: color palette, typography (Playfair Display / Work Sans / Roboto Mono), component styles (buttons, cards, inputs, navigation), animations, layout grid (8pt), spacing scale, CSS variables, and accessibility requirements (WCAG AAA).
- **fuckcorpo-features.md** — Feature specification: timer modes (quick log, live, automatic), salary calculator, break categories, leaderboards, achievements/badges, shareable content, data visualizations, privacy options, and educational/satirical content.

## Technical Requirements (from specs)

- **PWA** (Progressive Web App) — mobile-first, installable, offline-capable
- **Dark mode primary**, light mode optional
- **Local storage** as primary data store; optional account/backend for sync
- **Anonymous leaderboard** backend for community features
- **Fonts**: Google Fonts — Playfair Display (display), Work Sans (body), Roboto Mono (data/numbers)
- **Responsive breakpoints**: 320px (mobile), 768px (tablet), 1024px (desktop), 1440px (wide)
- **Max content width**: 1200px–1400px

## Design System Quick Reference

| Token | Value |
|---|---|
| Corporate Navy | `#0a1128` |
| Slate | `#1e2749` |
| Stock Market Green | `#00b559` |
| Stock Market Red | `#e63946` |
| Achievement Gold | `#ffd60a` |
| Cool Gray | `#778da9` |
| Muted Gold | `#c9a648` |

CSS variables are defined in `fuckcorpo-design-system.md` under "Implementation Notes" — use these as the starting point for any CSS/theme setup.

## Brand Voice

Irreverent but not mean-spirited. Pro-worker, anti-exploitation. Uses corporate/financial language satirically (e.g., "QUARTERLY EARNINGS REPORT" for bathroom stats, fake ticker symbols like `$POOP`). Copy should sound like an official corporate document that's been subverted.
