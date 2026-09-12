# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users
Smart home automation builders, remote workers, and privacy-conscious macOS power users who need their physical or digital environment (Home Assistant, "On Air" smart lights, Slack, SketchyBar) to reflect their live camera and microphone status without lag or battery drain.

## Product Purpose
"In Meeting" is a lightweight, zero-polling macOS menu bar application that monitors hardware capture states (cameras and microphones) using direct CoreAudio and CoreMediaIO listener blocks. It dispatches customizable webhooks, updates a local status file (~/.in-meeting), and triggers native notifications on status transitions with near-zero CPU and battery usage.

## Positioning
Unlike scripts that constantly poll logs (log stream) or query device state on intervals, In Meeting hooks directly into macOS kernel/system hardware event property listeners (kAudioDevicePropertyDeviceIsRunningSomewhere). It detects transitions instantly with under 40 MB RAM footprint, 0.0% idle CPU, and zero telemetry or tracking.

## Operating Context
macOS workstations (macOS 13.0+), home offices with smart lighting (Home Assistant, ESPHome "Do Not Disturb" / "Busy" indicators, Philips Hue, Homebridge), remote work calls (Zoom, Google Meet, FaceTime, Teams), and terminal workflows (SketchyBar, tmux, shell scripts via ~/.in-meeting).

## Capabilities and Constraints
- Direct hardware state capture via CoreAudio and CoreMediaIO property listener blocks.
- Dynamic hot-plug detection for USB/Thunderbolt webcams, AirPods, Continuity cameras.
- Per-device exclusion lists toggleable directly from the status menu.
- Temporary pause/resume detection toggle.
- Webhook engine supporting GET (query placeholder substitution) and POST (JSON body template), combined or separate URLs for audio/video, with exponential backoff retries.
- Local macOS notification banners via UserNotifications.
- Atomic status indicator at ~/.in-meeting for shell scripts and system bars.
- Launch at Login via SMAppService.mainApp.
- Sandbox disabled (com.apple.security.app-sandbox = false) by design to access CoreAudio/CoreMediaIO hardware registers.

## Brand Commitments
- Name: In Meeting
- Open source: MIT Licensed
- Privacy first: Zero telemetry, zero analytics, zero external network calls except user-configured webhooks.
- Visual assets: Native app icon (icon_256.png), live screenshots (menu.webp, general.webp, webhooks.webp).

## Evidence on Hand
- Working native macOS app code and Xcode project in repository.
- Real screenshots of the actual app: docs/menu.webp, docs/general.webp, docs/webhooks.webp.
- App icon: docs/icon_256.png.
- PRD: docs/prd.md.
- Architecture document: ARCHITECTURE.md.

## Product Principles
1. Native & Instant: Zero polling; direct macOS framework listeners; instantaneous response.
2. Lightweight & Invisible: Under 40 MB RAM, 0.0% idle CPU, lives quietly in the menu bar.
3. Uncompromising Privacy: No telemetry, no external calls, all observation executes strictly on-device.
4. Hackable & Automatable: Flexible webhook triggers, shell-friendly status files, Home Assistant ready.
