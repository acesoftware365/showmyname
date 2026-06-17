# ShowMyName Store Subscriptions

Last updated: June 17, 2026

## Prices

- Monthly Pro: `$0.99`
- Yearly Pro: `$9.99`

## Product IDs

Use the same product IDs in App Store Connect, Play Console, and the app code.

- Monthly: `showmyname_pro_monthly`
- Yearly: `showmyname_pro_yearly`

## Free Version

Free should stay useful:

- Airport / Pickup sign
- Basic message editing
- Basic ColorWave
- One logo image
- Ads visible

## Pro Version

Pro should unlock:

- No ads
- Premium Concert effects
- LED Dot Matrix controls
- Neon Glow, Pulse, Marquee, Wave
- Multiple logo images
- Logo rotation
- Logo effects
- Premium themes
- Future premium layouts/presets

## App Store Connect Setup

Create two auto-renewable subscriptions in the same subscription group.

Recommended group name:

- `ShowMyName Pro`

Subscriptions:

- `showmyname_pro_monthly`
  - Reference name: `ShowMyName Pro Monthly`
  - Duration: 1 month
  - Price: `$0.99`

- `showmyname_pro_yearly`
  - Reference name: `ShowMyName Pro Yearly`
  - Duration: 1 year
  - Price: `$9.99`

Review notes:

- Explain that Pro removes ads and unlocks premium sign effects, logo rotation, multiple images, and themes.
- Include Privacy Policy and Terms & Conditions URLs.
- Test with sandbox before submitting.

## Google Play Console Setup

Create a subscription product for each plan, or one base subscription with monthly/yearly base plans if using the newer Play Billing setup.

Product IDs:

- `showmyname_pro_monthly`
- `showmyname_pro_yearly`

Prices:

- Monthly: `$0.99`
- Yearly: `$9.99`

Benefits copy:

- No ads
- Premium concert text effects
- Multiple logos and image rotation
- Premium ColorWave themes
- Future premium display presets

## App Code

The app reads products from:

- `lib/services/subscription/subscription_manager.dart`

The paywall screen is:

- `lib/features/paywall/paywall_screen.dart`

Free/Pro preview is in:

- `Settings > Plan`

Use the preview buttons to see Free and Pro without buying while testing.
