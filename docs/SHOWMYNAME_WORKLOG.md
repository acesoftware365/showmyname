# ShowMyName Worklog

Last updated: June 17, 2026

This file is the project memory for the recent ShowMyName UI/UX work. Keep it updated when we make major design or behavior changes so we can remember what changed and undo pieces later if needed.

## Product Direction

ShowMyName should feel like a premium dark iOS-style sign app with purple neon accents, rounded cards, glassy panels, a large live preview, and a simple bottom mode selector.

The main split is:

- Airport / Pickup stays simple, plain, clean, and readable from far away.
- Concert / Event gets expressive text styles and animated sign effects.
- ColorWave focuses on color cycling and theme-like color changes.
- Logo focuses on uploaded images, multiple images, and fullscreen display.

## Current Screen Order

The home screen target layout is:

1. Live Preview
2. Mode Selector
3. Enter New Text
4. Mode-specific edit button, such as Edit Concert Style or Edit ColorWave Style
5. SHOW button
6. Rotate tip
7. Ad banner

Privacy Policy and Settings links were removed from the bottom because Settings already has those entry points.

## Airport / Pickup

Airport / Pickup was simplified so the main screen does not show a full settings panel.

Current behavior:

- Main action is Enter New Text.
- Text editing opens a popup with preview.
- Airport style settings live inside that popup.
- Airport text is simple only. No LED, no party effects, no animated lighting.
- Supported options: message, text size, text color, background color, bold, alignment, optional airport icon.
- Text box was reduced in height and centered to feel cleaner.

Undo note:

- Airport controls were previously visible as a card on the main screen. They are now inside the text popup.

## Concert / Event

Concert / Event was simplified like Airport but without deleting the effect features.

Current behavior:

- Main screen shows Enter New Text and Edit Concert Style.
- Concert style controls open in a popup.
- The old inline concert options were kept in code for easier undo/reference.
- Default concert effect is LED Dot Matrix.

Concert effects:

- Simple Text
- LED Dot Matrix
- Neon Glow
- Pulse
- Marquee
- Wave

LED Dot Matrix settings:

- LED color
- Brightness
- Glow intensity
- Panel border glow
- Dot size
- Dot spacing
- Animation: None, Pulse, Scroll left, Scroll right

Visual goal:

- LED Dot Matrix should look like a real concert LED panel: dark panel, glowing circular dots, purple neon border, readable text.

## ColorWave

ColorWave was simplified to match Airport and Concert.

Current behavior:

- Main screen shows Enter New Text and Edit ColorWave Style.
- ColorWave options open in a popup.
- Color cycling is intended to update the live preview and fullscreen display.
- Fade timing was adjusted so color changes use both hold time and transition duration.
- Theme-like color options were requested, inspired by the ShowMyName title where "ShowMy" is white and "Name" uses the accent color.

Important:

- User reported Fade was not working. Recheck this whenever ColorWave timing or animation changes.

## Logo

Logo mode was expanded.

Current behavior:

- Upload logo remains available.
- Multiple images button was added.
- File paths are hidden from the main screen.
- View details opens a popup if the user wants to see saved image paths.
- Rotate images toggle cycles through multiple uploaded images.
- Logo effect selector was added.
- Time per image was made faster than the original 3-second feel.

Logo effects:

- Fade
- Slide
- Zoom

Known UX note:

- User said the logo effects looked too similar. Slide and Zoom were made more distinct, but this still needs another visual pass.

## Themes

Settings now includes a Theme option.

Theme styles:

- Purple Neon
- Electric Blue
- Hot Pink
- Lime Glow

The app title uses the selected accent color for the "Name" part, matching the ShowMyName visual reference.

## Tablet / Large Screen

Mode selector height and labels were made bigger for tablet mode. User requested this after seeing the selector too short and cramped.

Target devices used during the work:

- iPhone 17 Pro Max simulator
- iPad A16 simulator

## Terms And Conditions

Settings now includes Terms & Conditions.

Important:

- The current Terms screen is a starter template for the app experience.
- Before charging users, the terms should be reviewed by a lawyer or replaced with final legal copy.

## Pro / Paid Direction

Suggested Pro features:

- Remove ads
- Concert effects: Neon Glow, Pulse, Marquee, Wave, advanced LED controls
- More saved presets
- Multiple logo/images and logo rotation
- Advanced ColorWave themes and custom palettes
- Export/share presets
- Premium fullscreen controls

Keep free version useful:

- Airport / Pickup basic sign
- One simple Concert style
- Basic ColorWave
- One logo upload

## Files Changed In This Work

Main files:

- `lib/features/home/home_screen.dart`
- `lib/features/home/widgets/mode_selector.dart`
- `lib/features/display/display_screen.dart`
- `lib/features/display/widgets/effect_sign.dart`
- `lib/models/sign_config.dart`
- `lib/models/sign_mode.dart`
- `lib/services/logo/logo_storage_service.dart`
- `lib/app/app_controller.dart`
- `lib/main.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/terms/terms_screen.dart`
- `lib/app/routing/app_router.dart`

Project housekeeping:

- `.gitignore`
- `docs/SHOWMYNAME_WORKLOG.md`

## Verification Notes

Build verification performed during the work:

- Android debug builds passed.
- App was run on phone and tablet simulators during UI checks.

Known tooling issue:

- `flutter analyze` may fail until the lint package/setup is cleaned up.
- `flutter test` may fail until test dependencies are configured.

## Open Issues

- User says the latest visual state is still wrong, but the last screenshot file expired before it could be read. Need a fresh screenshot or exact description.
- Recheck Logo mode bottom overflow near the ad banner.
- Recheck whether ColorWave Fade visibly changes color in preview and fullscreen.
- Recheck logo effect differences on device.
- Finalize legal terms before paid launch.

## AdMob Health System

Added for version 1.0.15+20.

Goal:

- Protect AdMob match rate by avoiding repeated ad requests when inventory is not filling.
- Keep rewarded ads faster by preloading one ad before the user taps a Pro feature.
- Avoid policy-risky behavior: no forced clicks, no fake impressions, no artificial ad refresh tricks.

Behavior:

- Rewarded ads are cached for a short safe window and reused when the user chooses "Watch ad".
- Banner and rewarded requests share a health manager with request spacing, in-flight protection, retry cooldown, and exponential backoff after failures.
- Failed loads and timeouts are counted locally per day so we can diagnose whether the app is asking too often or AdMob is not filling.
- If a Free user opens the home screen, the app quietly preloads the rewarded ad once.

Important:

- No app code can guarantee AdMob match rate stays high. Match rate also depends on country, demand, consent, policies, and ad inventory.
- This system reduces unnecessary requests, which is the safest lever inside the app.
