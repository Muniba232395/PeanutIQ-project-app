# Phase 2: App Shell and Dashboard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace Phase 1's placeholder Home with the real farmer app:
- a bottom tab shell: Home, Seed, Disease, Knowledge, More;
- the website-style top bar: logo, language globe, notifications bell, avatar menu;
- the More screen;
- the full Dashboard, ported from `PeanutIQ/src/pages/UserDashboard.jsx` and its components.

Seed, Disease, Knowledge, History, Advisories and Profile are placeholder screens until Phases 3–6.

**Architecture:**
- **Routing:** go_router `StatefulShellRoute.indexedStack`, one branch per tab. More's sub-screens (`/more/advisories`, `/more/history`, `/more/profile`) are child routes of the More branch.
- **Data:** Dashboard data comes from repositories behind Riverpod `FutureProvider`s. The providers are keyed on the signed-in user id, so they never show the previous user's data.
- **Actions list:** an `AsyncNotifier` with an optimistic toggle that reverts if the server call fails.
- **Styling:** everything copies the website's Tailwind classes, per the colour-parity rule.

**Spec:** `docs/superpowers/specs/2026-09-23-flutter-farmer-app-design.md` §6, §7 Dashboard, §9, §10.

**Plan format (ruling, 2026-09-23):**
- Phases 2–8 are planned and built in one session by the same agent.
- Plans specify files, interfaces and concrete test cases (name, input, expected); the code is written test-first during execution.
- Phase 1's plan carried full code; the TDD gate is unchanged.

## Global Constraints

Everything from Phase 1's Global Constraints still applies, plus:

**Colours:** exact website colours (`AppColors`). Tailwind v4 values are converted from tailwindcss 4.3.3. New values for this phase:

| Tailwind | Hex |
|---|---|
| yellow-400 | `FDC700` |
| teal-50 | `F0FDFA` |
| amber-50 | `FFFBEB` |
| red-800 | `9F0712` |

**Card style ("flat-card"):** white, 1px earth border, 16 px radius, shadow `0 2px 10px -4px rgba(0,0,0,.05)`, 24 px padding.

**Section headers:** 17 px bold charcoal, with a 20 px forest icon (stroke 2.5) and an 10 px gap.

**Time formats:**
- **Timestamps** (activity times): the backend sends naive UTC datetimes. `formatDate` appends `Z`, converts to `user.timezone`, and formats as `MM/dd/yyyy, HH:mm:ss` (24 h), matching `utils/date.js`. An unknown timezone falls back to UTC.
- **Due dates:** shown as `M/d/yyyy` in device-local time, like `toLocaleDateString()` in en-US.
- **Time ago:** buckets are "Just now" under 60 s, then minutes, hours and days, with singular/plural. It becomes translation keys: English copies the website, Urdu is new.

**Website behaviour kept:**
- Tip fallback text (EN and UR, verbatim from DailyAITip.jsx).
- Weather is fake (32 °C sunny; tomorrow 29 °C rain; Wed 30 °C breezy).
- Lifecycle defaults to `pegging` while the crop profile is unknown.
- Donut colours are `#22c55e`/`#eab308`/`#ef4444`, while the legend dots are forest/yellow-400/red-500. This mismatch is copied from the website.
- Notifications are always empty.

**Not copied from the website:**

| Behaviour | Website | App |
|---|---|---|
| Task toggle | updates only after the server succeeds | optimistic; reverts with an error toast on failure (spec §9) |
| Recent activity | a table | a card list (spec §7) |
| Navigation | side drawer | bottom tabs (user decision) |

## Review Focus

1. **A new user signs in on the same phone after a logout.** Expected: none of the previous farmer's tasks, activity or crop health is shown. Test: "dashboard data follows the signed-in user".
2. **Checking a task off fails** (offline). Expected: the checkbox flips back and an error toast shows. Test: "toggle reverts and toasts on failure".
3. **Some dashboard calls fail.** Expected: the rest of the dashboard still renders; the tip falls back to the website's text; failed sections show Retry. Test: "partial failure keeps the dashboard usable".
4. **A timestamp comes without a zone** ("2026-09-23T10:00:00"). Expected: it is treated as UTC and shown in the user's timezone. Test: `date_format_test` "naive timestamps are UTC".
5. **Small phone, large text, Urdu.** Expected: no overflow on the shell, top bar or dashboard. Test: "dashboard fits 360x640 at 1.5x in Urdu".

---

### Task 1: Dependencies, assets, translations, colours, date helpers

**Files:**
- `pubspec.yaml`: add `fl_chart` and `timezone`; add the asset `assets/images/`.
- `assets/images/farm-banner-bg.png`: copied from the web repo.
- `tool/translations/phase2.json`: new keys, then run the merge tool.
- `lib/core/theme.dart`: add the colours listed above.
- `lib/core/date_format.dart`:
  - `initTimeZones()`
  - `DateTime parseServerTime(String)`
  - `String formatDate(DateTime utc, String timezone)`
  - `String formatDueDate(DateTime)`
  - `String timeAgo(DateTime utc, Translations t, {DateTime? now})`
- `lib/main.dart`: call `initTimeZones()`.
- Test: `test/core/date_format_test.dart`.

**New keys (en / ur):**

`common.timeAgo`:

| Key | en | ur |
|---|---|---|
| `justNow` | Just now | ابھی ابھی |
| `minute` | {{count}} minute ago | {{count}} منٹ پہلے |
| `minutes` | {{count}} minutes ago | {{count}} منٹ پہلے |
| `hour` | {{count}} hour ago | {{count}} گھنٹہ پہلے |
| `hours` | {{count}} hours ago | {{count}} گھنٹے پہلے |
| `day` | {{count}} day ago | {{count}} دن پہلے |
| `days` | {{count}} days ago | {{count}} دن پہلے |

`dashboard.app` (the texts the website hardcodes):

| Key | en | ur |
|---|---|---|
| `tipTitle` | Daily AI Tip | روزانہ اے آئی ٹپ |
| `tipFallback` | According to the weather forecast, rain is expected today. Ensure proper field drainage. | موسم کی پیشگوئی کے مطابق آج بارش کا امکان ہے۔ فصل کی نکاسی کا خیال رکھیں۔ |
| `defaultFirstName` | Farmer | Kisan Bhai (the website's literal) |
| `defaultName` | Returning Farmer | کسان بھائی |
| `upcomingTitle` | Upcoming Actions | آنے والے اقدامات |
| `aiRecommended` | AI Recommended | اے آئی تجویز کردہ |
| `noActions` | No upcoming actions. | کوئی آنے والے اقدامات نہیں ہیں۔ |
| `lifecycleTitle` | Crop Lifecycle Stage | فصل کی نشوونما کا مرحلہ |
| `noAlerts` | No active alerts | کوئی فعال انتباہ نہیں |
| `noAlertsDesc` | Your farm conditions are optimal. | آپ کے کھیت کے حالات بہترین ہیں۔ |
| `toggleFailed` | Could not update the task | کام اپ ڈیٹ نہیں ہو سکا |
| `loadFailed` | Could not load this section | یہ حصہ لوڈ نہیں ہو سکا |

`dashboard.app.stages`:

| Key | en | ur |
|---|---|---|
| `sowing` | Sowing | بوائی |
| `flowering` | Flowering | پھول آنا |
| `pegging` | Pegging | پھلیاں بننا |
| `podFill` | Pod Fill | پھلی بھرنا |
| `harvesting` | Harvesting | کٹائی |

`dashboard.activities`:

| Key | en | ur |
|---|---|---|
| `action` | Action | عمل |
| `details` | Details | تفصیلات |
| `time` | Time | وقت |
| `noActivity` | No recent activity. | کوئی حالیہ سرگرمی نہیں۔ |

Other new keys:

| Key | en | ur |
|---|---|---|
| `layout.header.noNotifications` | No new notifications | کوئی نئی اطلاع نہیں |
| `layout.tabs.home` | Home | ہوم |
| `layout.tabs.seed` | Seed | بیج |
| `layout.tabs.disease` | Disease | بیماری |
| `layout.tabs.knowledge` | Knowledge | معلومات |
| `layout.tabs.more` | More | مزید |
| `layout.more.language` | Language | زبان |

**Tests (`date_format_test`):**
- "naive timestamps are UTC": `parseServerTime('2026-09-23T10:00:00')` equals `DateTime.utc(2026,9,23,10)`; strings ending in `Z` or `+05:00` parse correctly.
- "formatDate converts to the user's timezone": 10:00 UTC with `Asia/Karachi` gives `09/23/2026, 15:00:00`.
- "formatDate falls back to UTC for unknown zones": `'Mars/Olympus'` gives `09/23/2026, 10:00:00`.
- "formatDueDate": `M/d/yyyy` in local time.
- "timeAgo buckets": 30 s → Just now; 1 min → "1 minute ago"; 5 min → "5 minutes ago"; 1 h → "1 hour ago"; 3 h; 1 day; 4 days. In Urdu, 3 h → "3 گھنٹے پہلے".
- The translations key test is extended with every new key above, checked in both languages.

### Task 2: Dashboard data layer

**Files:**
- `lib/features/advisories/data/advisory.dart`: `Advisory {id, title, message, type, severity, createdAt}` with `fromJson`.
- `lib/features/advisories/data/advisories_repository.dart`: `fetch({String? type, int? limit})` returns `List<Advisory>` (`GET /dashboard/advisories`).
- `lib/features/dashboard/data/models.dart`:
  - `ActionItem {id, title, category, dueDate?, isCompleted}` with `copyWith`
  - `ActivityEntry {action, details?, timestamp}`
  - `CropProfile {stage, goodPct, averagePct, poorPct}`
- `lib/features/dashboard/data/dashboard_repository.dart`:
  - `fetchActivities({int limit = 5})`
  - `fetchCropProfile()`
  - `fetchActions()`
  - `setActionCompleted(String id, bool completed)`
- `lib/features/dashboard/data/weather_repository.dart` (fake): `today` plus two `WeatherDay {dayKey, temp, conditionKey, kind}` entries.
- `lib/features/dashboard/dashboard_providers.dart`:
  - `activitiesProvider`, `latestAlertProvider` (Advisory?), `dailyTipProvider` (String?), `cropProfileProvider` (all FutureProviders that watch the user id);
  - `actionsProvider`: an `AsyncNotifier<List<ActionItem>>` with `toggle(id)` that returns `Future<bool>` (false means it reverted).
- Test: `test/features/dashboard/dashboard_data_test.dart`.

**Tests:**
- Parsing: an advisory JSON gives the right fields (naive `created_at` is UTC); the crop profile maps `health_*_pct`; an action with a null `due_date` is allowed.
- Requests:
  - activities: `GET /dashboard/activities` with query `{limit: 5}`;
  - latest alert: query `{type: alert, limit: 1}`; an empty list gives null;
  - tip: query `{type: tip, limit: 1}`; returns `message`, or null when empty.
- "toggle is optimistic": with the PUT held, the state already shows the task completed. After the server answers, the body was `{is_completed: true}`.
- "toggle reverts and toasts on failure": PUT returns 500, the state goes back to not completed, and `toggle` returns false.
- "dashboard data follows the signed-in user": sign in as user A (activities A), log out, sign in as user B. `activitiesProvider` refetches, and the result contains B's data only.

### Task 3: App shell, top bar, More, placeholders

**Files:**
- `lib/core/router.dart`:
  - `Routes.home='/home'`, `seed='/seed'`, `disease='/disease'`, `knowledge='/kb'`, `more='/more'`, `advisories='/more/advisories'`, `history='/more/history'`, `profile='/more/profile'`;
  - a `StatefulShellRoute.indexedStack` holding the five branches;
  - `appRedirect` is unchanged: shell routes count as "signed-in routes".
- `lib/features/shell/app_shell.dart`:
  - a Scaffold with `AppTopBar` and the branch navigator;
  - the tab bar: white, earth top border. The active tab shows a forest pill with a white icon (the website's `bg-forest text-white` active nav) and a forest bold label; inactive tabs are charcoal at 70%.
  - Tab icons (lucide): `layoutDashboard`, `bean`, `scanSearch`, `bookOpen`, `menu`.
- `lib/features/shell/app_top_bar.dart`:
  - **Bar:** white, 64 px tall, earth bottom border, with `AppLogo` (24) and `Wordmark` (18) at the start.
  - **Globe button:** charcoal at 70%, `p-2`, round. Its menu offers English/Urdu: bold charcoal 14, white, 2px earth border, 12 px radius, no shadow.
  - **Bell:** opens a bottom sheet with a sand header row ("Notifications", bold 14) and an empty state (32 px gray-300 bell, "No new notifications" in 14 gray-500).
  - **Avatar:** a 32 px circle in `#2D5A27` with white initials (the ui-avatars rules: letters only, first letters of up to two words, uppercase; "F" when empty) plus a chevron. Its menu has View Profile (charcoal, `user` icon) and Logout (terracotta, `logOut` icon).
- `lib/features/shell/more_screen.dart`:
  - a white card list in the website sidebar's nav style: a 20 px icon at 70% and a 14 px bold charcoal label;
  - rows: History (`history`), Advisories (`triangleAlert`), Profile (`user`);
  - a Language row showing the current language, which opens the same menu;
  - a Logout row in terracotta.
- `lib/features/shell/placeholder_screen.dart`: `PlaceholderScreen(titleKey)`, used for the Seed, Disease, Knowledge, History, Advisories and Profile routes until later phases.
- `lib/features/assistant/assistant_launcher.dart`: `assistantLauncherProvider` (`Notifier<int>`). `open()` increments a counter that Phase 7 listens to; Phase 2 only exposes it.
- Delete `lib/features/home/home_placeholder_screen.dart`, and update the tests that expected "Welcome back, Ali!" to find it on the dashboard banner.
- Test: `test/features/shell/app_shell_test.dart`.

**Tests:**
- "signed-in farmer lands on Home with five tabs": the labels Home, Seed, Disease, Knowledge and More are present, and the banner shows "Welcome back, Ali!".
- "tabs switch and keep their own stacks": go to More, then Advisories; switch to Home and back to More; the Advisories screen is still shown.
- "avatar menu logs out": tap the avatar, then Logout, and the Login screen shows.
- "avatar shows initials": for the name "Ali Khan" it shows "AK".
- "bell opens the empty notifications sheet": "No new notifications" is shown.
- "More → Profile opens profile placeholder".
- "language from the top bar switches to Urdu": the tab label reads "ہوم".

### Task 4: Dashboard screen

**Files:** `lib/features/dashboard/dashboard_screen.dart` plus these widgets in `lib/features/dashboard/widgets/`:

| Widget | Ported from |
|---|---|
| `welcome_banner.dart` | the website banner: `#0F5A27` background with `farm-banner-bg.png` covering at right-centre, mirrored in RTL; 20 px bold white title, 24 px logo (white/lime); 13 px green-50 subtitle at 90% |
| `daily_tip_card.dart` | DailyAITip, including the RobotFace CustomPainter, the float animation and the pulsing gold mic that calls `assistantLauncherProvider.open()` |
| `upcoming_actions_card.dart` | UpcomingActions; the category icon comes from irrigation/disease/other |
| `weather_card.dart` | the weather card |
| `latest_advisory_card.dart` | severity pill `#FDE8E8`/red-700, red-800 title, "Read more details" to `/more/advisories`, the empty state |
| `crop_health_card.dart` | an `fl_chart` PieChart ring: radius 12, centre space fills a 144 px box, starts at the top; centre shows "NN%" + "GOOD"; legend; "View full report" to `/more/history` |
| `crop_lifecycle_card.dart` | CropLifecycle: stepper, progress line, pulse and ping on the current stage, horizontal scroll at a minimum width of 480 |
| `quick_actions_card.dart` | three tiles linking to the seed, disease and kb tabs |
| `recent_activity_card.dart` | a card list plus "View All Activity" to `/more/history` |
| `section_card.dart` | the shared flat-card and section header |

Pull-to-refresh invalidates all the dashboard providers.

**Tests (`test/features/dashboard/dashboard_screen_test.dart`, all at phone size):**
- "renders every section with API data": the tip message, a task title, "32°C", the advisory title, "70%" (from `health_good_pct`), a stage label, the three quick-action labels, the activity action and its formatted time.
- "tip falls back to the website text when there is no tip".
- "tapping a task toggles it and sends PUT".
- "toggle failure reverts and shows a toast" (error toast `dashboard.app.toggleFailed`).
- "quick action switches to the Disease tab".
- "Read more details opens Advisories".
- "partial failure keeps the dashboard usable": activities return 500 and the rest render; that section shows `dashboard.app.loadFailed` and Retry, and Retry refetches.
- "pull to refresh refetches": drag down, and the activities request count increases.
- "dashboard fits 360x640 at 1.5x in Urdu": no exceptions while scrolling to the end.

### Task 5: Verify on the emulator, update README

- A release build on the emulator, checked with screenshots of Home (EN and UR), More and the notifications sheet. There's no backend, so the dashboard shows error states and fallbacks; check that those look right.
- README: mention the tabs.
