# NotPlater Nameplate Addon for 2.4.3 and 3.3.5 Clients

<p align="center">
  <img src="/images/demo.png">
</p>

NotPlater brings Plater-inspired, threat-aware nameplates to TBC (2.4.3) and Wrath (3.3.5a). It focuses on rich threat visualization, a modern aura engine, and highly customizable layouts tuned for both clients.

## Feature Highlights
- Threat suite for tank vs DPS/healer: color-coded health bars, threat %, differential, and numeric rank with independent styling.
- Customizable cast/health/name/level text (with color overrides), target highlighting and a default CVar toggle to hide the Blizzard castbar.
- Resize / Style individual components (health bar, cast bar, threat elements, target/boss icons, target-target text) to keep dense pulls readable.
- Aura engine with configurable buff/debuff frames, swipe cooldowns, manual lists, and automatic tracking filters.
- Component display order controls so you can raise/lower plate elements when stacking nameplates.
- Profile import/export with shareable strings or links plus group version checks to keep parties aligned.
- Simulator frame and polished defaults to preview layouts without needing live targets.
- Supports all shipped localizations so you can configure in your preferred language.

## Installation
- 2.4.3: Rename the downloaded folder to `NotPlater-2.4.3` and place it in `..\Interface\AddOns\NotPlater-2.4.3`.
- 3.3.5: Rename the downloaded folder to `NotPlater-3.3.5` and place it in `..\Interface\AddOns\NotPlater-3.3.5`.

If you find any bugs feel free to message me (richsteini on Discord) or report an issue.

## Settings (/np or /notplater or click the minimap button)

<p align="center">
  <img src="/images/demo_settings.png">
</p>

Open the options via the minimap button or /np /notplater. All features above live here, including profile import/export, aura tracking, component ordering, and simulator toggles.

## Aura Engine (Buffs & Debuffs)

<p align="center">
  <img src="/images/demo_buffs.png">
</p>

- Tracking and filters: Automatic or manual modes with toggles for player/other-player auras, dispellable/enrage/magic buffs, crowd control, NPC buffs/debuffs, short dispellable buffs on players only, and other NPC auras. Choose which units are polled (target, focus, mouseover, arena) and optionally learn durations via combat log tracking.
- Layout: Up to two frames (debuffs in Aura Frame 1, optional buffs in Aura Frame 2) with grow direction, anchor, offsets, per-row counts, icon size, border thickness, spacing, opacity, tooltips, stacking of similar auras, shortest-remaining-time display, sorting, and animations.
- Timers and counters: Configurable stack counter font/outline/color/shadow and position; timer font/size/outline/color with decimals toggle and an option to hide OmniCC/TullaCC while the built-in timer is visible; per-frame timer anchors and shadow toggles.
- Cooldowns and borders: Swipe animation styles (top-to-bottom, swirl, or RichSteini), selectable swipe textures, invert/visibility toggles, and border color rules (type colors or custom colors for dispellable, enrage, buff, crowd control, offensive/defensive cooldowns, and default).
- Manual lists: Per-profile blacklists and extra lists for debuffs and buffs with add/remove prompts by spell name or ID.

<p align="center">
  <img src="/images/demo_buffs_config.png">
</p>

## Threat Display

<p align="center">
  <img src="/images/demo4.png">
</p>

- Threat color coding: Three healthbar colors per role, with optional class colors.
- Threat status bar/text: Threat percent as a bar or text with separate colors for 100%/90%/below 90%.
- Threat differential text: Shows how far you are from first place (or how far others are from you) with per-role colors.
- Threat number text: Your rank on the threat table with distinct colors for #1, above 80%, and below 80%.

## Stacking & Component Order
<p align="center">
  <img src="/images/demo_component_order.png">
</p>
- Component ordering UI lets you raise/lower health, cast, threat, aura, icon, and text elements so they stack cleanly; tune frame strata/levels alongside general stacking margins and overlap settings.

## NotPlater Simulator Frame

<p align="center">
  <img src="/images/notplater_simulator_frame.gif">
</p>

The simulator mimics a live nameplate (including a 10-player threat scenario tooltip) so you can tune layouts without hunting for mobs. Drag it from the outer region and target/untarget it with a click.

## Profile Sharing

<p align="center">
  <img src="/images/demo_export.png" width="55%"> <img src="/images/demo_import.png" width="35%">
</p>

- Export: Generate a shareable profile string, review its summary, and optionally insert a clickable link directly into chat for fast sharing.
- Import: Paste a received string, choose the target profile name, auto-activate it if desired, and review an import summary before switching.
- Works alongside standard profile management (copy/reset) and group version checks so everyone runs a compatible setup.

## Acknowledgements

The design is inspired by the Plater addon.
