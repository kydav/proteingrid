# Protein Grid: making money

_Last updated 2026-10-31._

## The model: freemium with a cheap Pro

Protein Grid's edge is speed: one tap to log, no food database, no account. The
free app keeps all of that. Pro sells **seeing your progress** and **making the
app yours**. Those are the things people who already log every day want next.

### Free (unchanged for everyone)
- One-tap logging, home-screen shortcuts, custom amounts, labels
- Daily goal, progress ring, current streak, 7-day chart
- The Grid and history for the **last 5 weeks**
- One daily reminder, which now skips the rest of the day once the goal is hit
- CSV export

### Pro (`ProteinGrid Pro` entitlement in RevenueCat)
- **THE GRID, full year:**
  - 53 weeks of goal days, GitHub-style, the app's namesake;
  - best run;
  - this year's goal-day count.
- **Full history:** browse any day, not just the last 5 weeks.
- **Your own quick buttons:** up to 8 amounts, each with an optional name ("Shake · 40g").
- **Up to 3 daily reminders.**

### Price (recommended)
| Package | Price | Notes |
|---|---|---|
| **Yearly** | **$9.99/yr** with a **7-day free trial** | Default, listed first ("best value") |
| **Lifetime** | **$19.99** | People who hate subscriptions buy this. Expect about 40% of buyers. |
| Monthly | optional, $1.99 | Skip at first, it just splits buyers |

Competitors are higher. Protein Pal and Protein Tracker run about $5/mo or $30–40/yr, but they
include AI photo logging. Protein Grid is the cheap, fast, no-nonsense
option, and its price should say so.

## Where the paywall shows (built)
Every gate opens one sheet (`lib/features/pro/pro_paywall_sheet.dart`) with
a headline that matches the tap:

| Trigger | Headline |
|---|---|
| Tap the locked part of the Grid, or "YOUR YEAR" | "See your whole year" |
| Day selector going back more than 5 weeks | "Go back further" |
| "Edit" on the log sheet, or Settings → Edit quick-log buttons | "Make the buttons yours" |
| Settings → Add another reminder | "More reminders" |
| Settings → "See Pro" card at the top | "ProteinGrid Pro" |
| **Third day the goal is hit**, shown once, 1.5s after the win | "See your whole year" |

The paywall lists whatever packages the RevenueCat **current offering** has,
sorted yearly → lifetime → monthly. It shows trial/renewal terms, Restore,
and Terms + Privacy links (auaha.app/proteingrid/terms and /privacy), which
App Review requires for subscriptions.

The native **rating prompt** fires on the 5th goal day. The OS limits how often it actually shows.

## Setup you need to do (store + RevenueCat)
1. **App Store Connect** → Protein Grid → Subscriptions: create group "ProteinGrid Pro".
   - Product `pg_pro_yearly`: $9.99/yr with a 1-week free-trial introductory offer.
   - In-App Purchases → Non-consumable `pg_pro_lifetime`: $19.99.
   - Each needs a review screenshot of the paywall, so do these after a TestFlight build.
2. **RevenueCat** (Protein Grid project):
   - attach both products to the existing `ProteinGrid Pro` entitlement;
   - offering `default` gets packages `$rc_annual` → yearly and `$rc_lifetime` → lifetime;
   - mark it current.
3. **Android (optional, later):**
   - create the same products in Play Console;
   - add a Play app in RevenueCat;
   - paste its `goog_…` key into `_rcGoogleKey` in `lib/core/purchases_service.dart`.

   Until then **Pro is simply unlocked on Android**, since there's no way to buy it there.
4. Update the App Store description's last line and the privacy page with: "Optional Pro subscription; payment handled by Apple."

## Later Pro features (in order of value)
1. **Home-screen and lock-screen widgets.** The #1 ask in this category. Needs a WidgetKit extension plus an App Group; the group is already in the entitlements.
2. **Apple Health sync** (write protein, read body weight for goal suggestions). Strong ASO term.
3. **Share card:** a picture of your Grid or streak to post. Keep it **free** with the app name on it, since it's marketing.
4. **AI estimate:** "describe your meal" → grams, via a Firebase AI call with App Check. This is what competitors charge for.
5. Themes and alternate app icons, cheap to make on the arcade look.
