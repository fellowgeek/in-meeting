---
name: In Meeting
description: Minimalist Swiss Signal & Raycast Elegance design system for In Meeting macOS utility
colors:
  canvas-dark: "#08090c"
  canvas-light: "#f8fafc"
  surface-dark: "#101218"
  surface-raised-dark: "#151821"
  surface-subtle-dark: "#0d0e14"
  border-dark: "#222634"
  border-hover-dark: "#32384c"
  text-primary-dark: "#f8fafc"
  text-secondary-dark: "#94a3b8"
  text-muted-dark: "#64748b"
  text-code: "#cbd5e1"
  white: "#ffffff"
  signal-red: "#f43f5e"
  signal-amber: "#f59e0b"
  signal-emerald: "#10b981"
  mac-traffic-close: "#ff5f56"
  mac-traffic-min: "#ffbd2e"
  mac-traffic-zoom: "#27c93f"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Inter', sans-serif"
    fontWeight: 600
    letterSpacing: "-0.03em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Inter', sans-serif"
    fontWeight: 400
    lineHeight: 1.6
  mono:
    fontFamily: "'SF Mono', 'JetBrains Mono', Menlo, ui-monospace, monospace"
rounded:
  xs: "4px"
  sm: "6px"
  md: "10px"
  lg: "14px"
  full: "9999px"
---

# Design System: In Meeting

## Overview
"In Meeting" embraces a **Minimalist Swiss Signal & Raycast Elegance** visual identity. Built for power users, developers, and smart home tinkerers, it prioritizes instant communication, surgical status accents, and authentic macOS craftsmanship over generic decorative gradients or heavy artificial glassmorphism.

## Colors
- **Canvas**: Deep Obsidian (`#08090c`) for Dark Mode; Pure Ice (`#f8fafc`) for Light Mode.
- **Surface Elevation**: Milled Graphite (`#101218`), Raised Control (`#151821`), and Subtle Recess (`#0d0e14`).
- **Hairline Borders**: Fine 1px stroke (`#222634` default, `#32384c` on hover).
- **Surgical Signal Accents**:
  - **Tally Red (`#f43f5e`)**: Signals active camera capture and "ON AIR" broadcast states.
  - **Tally Amber (`#f59e0b`)**: Signals live microphone recording.
  - **Signal Emerald (`#10b981`)**: Signals idle/available states, Home Assistant webhook dispatches, and successful operations.
- **macOS Window Accents**: Close (`#ff5f56`), Minimize (`#ffbd2e`), Zoom (`#27c93f`).

## Typography
- **Display & Headings**: Native Apple San Francisco (`-apple-system, BlinkMacSystemFont, "SF Pro Display"`) with tight negative tracking (`-0.03em` to `-0.04em`), robust line-height (`1.08` to `1.15`), and high contrast.
- **Body**: `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter"` with maximum measure constrained to 65–72ch for optimal readability.
- **Telemetry & Monospace**: `ui-monospace, "SF Mono", "JetBrains Mono", Menlo` for hardware latencies, JSON webhooks, terminal commands, and shell snippets.

## Layout
- **Max Width**: 1120px responsive container with 24px horizontal padding.
- **Rhythm**: Generous vertical section separation (80px), tight micro-groupings (8–14px). Headings maintain greater clearance above than below.
- **Responsive Stacking**: Multi-column workbench modules collapse to single-column interactive cards on screens below 960px.

## Elevation & Depth
- **Borders over Shadows**: Relies primarily on 1px hairline micro-borders (`#222634`) rather than thick decorative drop shadows.
- **Soft Diffusion**: Elevated window frames and floating cards use subtle soft-blurred multi-stop shadows (`0 16px 40px -8px rgba(0, 0, 0, 0.6), 0 4px 12px -2px rgba(0, 0, 0, 0.4)`). Zero-blur hard block shadows are explicitly rejected.

## Shapes
- **Corner Radii**: 4px (`--radius-xs`), 6px for pills/switches (`--radius-sm`), 10px for cards/boxes (`--radius-md`), 14px for master window frames (`--radius-lg`), and 9999px for status dots and badges (`--radius-full`).
- **Form Language**: Compact, tactile, rounded rectangles evoking physical hardware console keys and macOS Sequoia window chrome.

## Components
- **Interactive Hardware Simulator**: Real-time simulation of camera/microphone capture states, updating simulated menu bar item, broadcast tally sign, status file, and outgoing webhook JSON.
- **Segmented Native Showcase**: macOS window frame with traffic light controls and responsive tabs showcasing native screenshots (`menu.webp`, `general.webp`, `webhooks.webp`).
- **Terminal Install Bar**: One-click copyable Homebrew command pill with instant visual feedback.

## Do's and Don'ts
- **DO** keep signal colors surgical: use tally red and amber exclusively for active device state or warnings.
- **DO** use authored inline SVGs with identical stroke weight (1.5px / 2px).
- **DO** maintain strict body text contrast (≥ 4.5:1).
- **DON'T** use gradient text or neon ambient background blurs.
- **DON'T** use kickers or eyebrows above headings.
- **DON'T** animate screenshots or images on hover.
