# PeanutIQ Farmer Mobile App (Flutter) — Design

**Date:** 2026-09-23
**Status:** Approved in conversation, awaiting written-spec review

## 1. Goal and scope

Build an Android app in Flutter that gives **farmers** the same features as the PeanutIQ web frontend (`src/`). It talks to the existing FastAPI backend without changing it.

**In scope:**
- Auth screens: login, signup, OTP, profile setup.
- The 7 farmer screens:
  - Dashboard
  - Seed Intelligence
  - Disease Intelligence
  - History
  - Advisories
  - Knowledge Base
  - Profile
- The floating AI assistant.
- The maintenance screen.
- English and Urdu, with a right-to-left layout for Urdu.

**Out of scope:**
- Admin and researcher screens. Those roles keep using the website.
- iOS. It is deferred.
- Backend changes.
- Making the website's fake features real.

**Fidelity rule:** where the website uses placeholder data or canned behaviour, the app does the same. Each fake part sits behind its own repository class so it can be switched to real data later.

**Fake parts to copy:**
- Weather card.
- Seed and Disease analysis results. The upload also sends fixed status and confidence values.
- Assistant replies.
- Knowledge Base "Ask AI".
- Notifications (always empty).
- The Resend OTP button, which does nothing.

**Website bugs fixed rather than copied:**
- Language matching is case-insensitive: `urdu`/`Urdu` → `ur`, `english`/`English` → `en`.
- A 401 response logs the user out.

## 2. Tech stack

| Concern | Choice |
|---|---|
| State management | `flutter_riverpod` |
| Routing | `go_router` (a `StatefulShellRoute` for the tabs) |
| HTTP | `dio` |
| Token storage | `flutter_secure_storage` |
| Other storage (user JSON, language) | `shared_preferences` |
| i18n | A small in-house `Translations` class (dot-path lookup, i18next `{{name}}` placeholders, English fallback, list/object values) over the website's `en.json` and `ur.json`. It replaces `easy_localization`, which uses `{name}` placeholders and handles list values poorly. |
| Charts | `fl_chart` |
| Camera and gallery | `image_picker` |
| Voice recording | `record` (AAC/m4a) |
| Audio playback | `just_audio` |
| Permissions | `permission_handler` |
| PDF | `pdf`, `printing` (share or save) |
| Formatted text (bot replies, pathology) | `flutter_html`, or a small bold/line-break parser |
| Dates and timezones | `intl`, `timezone` |
| Fonts | Inter, Plus Jakarta Sans, Noto Nastaliq Urdu through `google_fonts`. They are fetched at runtime and cached until Phase 8, which bundles them for offline use. |
| Icons | `lucide_icons_flutter`, or Material icons |

**Targets:**
- Android, minSdk 23.
- Flutter 3.47 stable.
- Developed in VS Code with the Flutter extension; runs on an Android Studio emulator.

## 3. Project structure

The app lives in its **own git repository** at `/Users/abdulrazzaq/Documents/PeanutIQ-Mobile`, with the Flutter project at the repo root. It is separate from the web/backend repo `PeanutIQ`.

**Assets and translations:** copied once from `PeanutIQ/src` (locales, `farm-banner-bg.png`). After that they are maintained independently. Nothing refers back to the web repo.

**Names:** the Dart package is `peanutiq` and the Android package is `com.peanutiq.app`.

```
lib/
  main.dart            init storage, localization, ProviderScope, runApp
  app.dart             MaterialApp.router, theme, locale, Directionality
  core/
    config.dart        API_URL from --dart-define; default http://10.0.2.2:8000/api/v1
    api_client.dart    dio + interceptors (token, 401, 503, error mapping)
    storage.dart       secure token; prefs for user JSON and language
    theme.dart         colours, text theme, card and button styles
    router.dart        go_router with redirects (auth, maintenance)
    errors.dart        AppException: network | unauthorized | server(detail)
    date_format.dart   port of utils/date.js; time-ago helper
    widgets/           AppCard, toast service, EmptyState, ErrorRetry, LoadingView, AppTopBar
  features/
    auth/              data/auth_repository.dart; auth_controller.dart; screens
    dashboard/         repositories (activities, advisories, crop profile, actions, weather-fake); widgets
    scan/              scan_repository.dart (upload); scan_analysis_repository.dart (fake results); ScanFlowScreen(type)
    history/           list, filter chips, detail bottom sheet, PDF
    advisories/
    knowledge/         knowledge_repository.dart; kb_ask_ai_repository.dart (fake); list, detail, edit screens
    profile/
    assistant/         assistant_repository.dart (canned replies and activity logging); chat sheet and widgets
    maintenance/
    report/            PDF builders for the seed, disease and history reports
  assets/
    translations/en.json, ur.json
    images/            farm-banner-bg.png, auth background, logo
    fonts/
```

Development builds allow cleartext HTTP through a debug-only `network_security_config`.

## 4. Theme

**Colours:**

| Name | Value |
|---|---|
| sand (background) | `#F9FAFC` |
| forest (primary) | `#07571C` |
| terracotta | `#E07A5F` |
| charcoal (text) | `#3D4035` |
| earth (borders) | `#E5E7EB` |
| gold | `#f0c169` |
| banner green | `#0F5A27` |
| lime | `#A3D977` |
| auth button | `#324329` |
| dark text | `#1D2B15` |
| chart terracotta | `#C05A3B` |
| health: good / average / poor | `#22c55e` / `#eab308` / `#ef4444` |
| seed chart orange | `#f97316` |
| avatar background | `#2D5A27` |

**Components:**
- **Card:** white, 1px earth border, 16px radius, shadow `0 2 10 -4 rgba(0,0,0,.05)`.
- **Primary button:** forest background, white bold text, 12px radius.
- **Inputs:** outlined with a forest border.

**Fonts:**
- Body text: Inter.
- Headings: Plus Jakarta Sans.
- When the locale is `ur`: Noto Nastaliq Urdu.

## 5. API contract (frontend-used subset)

All paths are relative to `API_URL`. Every request except the OTP requests sends `Authorization: Bearer <token>`.

**Auth and user**

| Method | Path | Body or query | Response |
|---|---|---|---|
| POST | `/auth/request-otp` | `{identifier}` | — |
| POST | `/auth/verify-otp` | `{identifier, otp}` | `{access_token, token_type, user}`; error in `detail` |
| GET | `/users/me` | — | user object |
| PUT | `/users/me` | `{name?, farm_location?, language_preference: 'english'\|'urdu', timezone?}` | user object |

User fields used: `id, name, role, identifier, email, farm_location, language_preference, timezone`.

**Dashboard and advisories**

| Method | Path | Body or query | Response |
|---|---|---|---|
| GET | `/dashboard/activities?limit=5` | — | `[{action, details, timestamp}]` |
| POST | `/dashboard/activities` | `{action, details}` | — |
| GET | `/dashboard/advisories` | optional `type=alert\|tip`, `limit` | `[{id, title, message, type, severity, created_at}]` |
| GET | `/dashboard/crop-profile` | — | `{health_good_pct, health_average_pct, health_poor_pct, stage}` |
| GET | `/dashboard/actions` | — | `[{id, title, category, due_date, is_completed}]` |
| PUT | `/dashboard/actions/{id}` | `{is_completed}` | — |

**Scans and knowledge base**

| Method | Path | Body or query | Response |
|---|---|---|---|
| POST | `/scans/` | multipart: `file`, `type` (`Seed Intelligence`\|`Disease Intelligence`), `title`, `status`, `confidence_score` | ignored |
| GET | `/scans/` | — | `[{id, type, title, status, confidence_score, image_url, created_at}]` |
| GET | `/knowledge/articles` | — | articles (`created_at` becomes `date`) |
| PUT | `/knowledge/articles/{id}` | full article | — |
| DELETE | `/knowledge/articles/{id}` | — | — |

**Maintenance**

| Method | Path | Body or query | Response |
|---|---|---|---|
| GET | `/admin/system/maintenance/status` | — | `{active, end_time}` |

## 6. Navigation

**Sign-in flow and redirects:**
- **Splash:** loads the stored auth.
- **Not logged in:** `/login`. Login and Signup send `{identifier}` and go to `/verify-otp`.
- **After OTP:**
  - A new user (signup intent, or no `farm_location`) goes to `/profile-setup`.
  - Otherwise the user goes to `/home`.
  - Role `admin` or `researcher`: show the "use the website" message, then log out.
- **Guard:** only authenticated farmers can reach the main app. A 503 anywhere goes to `/maintenance`.

**Main app** (`StatefulShellRoute`, one navigator per tab):

| Tab | Route | Screens |
|---|---|---|
| Home | `/home` | Dashboard |
| Seed | `/seed` | Seed scan flow |
| Disease | `/disease` | Disease scan flow |
| Knowledge | `/kb` | List (search and categories) → `/kb/:id`, `/kb/:id/edit` |
| More | `/more` | → `/more/advisories`, `/more/history`, `/more/profile`; language switch; logout |

**Top bar:**
- The screen title.
- A notifications bell that opens an empty bottom sheet with "mark all read".
- The avatar, drawn as initials.

**The floating assistant button:**
- Appears above the tab bar on every tab.
- Modals become bottom sheets.

## 7. Screens

### Auth
- **Header:** a green header with the logo and tagline, a short version of the website's auth panel. It includes the EN/اردو switch.
- **Login and Signup:** a single **email** field. The backend's `identifier` is an `EmailStr`, and the code is sent by email, so phone numbers can't work.
  - The field uses the email keyboard.
  - The value is trimmed and checked against `^[^\s@]+@[^\s@]+\.[^\s@]+$` before sending.
- **OTP:**
  - 6 numeric boxes with auto-advance, and backspace moves back.
  - Pasting a 6-digit code fills all the boxes.
  - Submit is disabled until all 6 digits are in.
  - "Change contact" goes back to Login.
  - Resend is inert.
- **Profile setup:**
  - Name: required, letters, marks and spaces only (`^[\p{L}\p{M}\s]*$`).
  - Region: from `FARM_REGIONS` (Attock, Chakwal, Rawalpindi, Talagang, all Punjab).
  - Language.
  - Submits with `PUT /users/me`.

### Dashboard (Home)
In order:
1. Welcome banner, mirrored in RTL.
2. Daily AI tip (API tip, falling back to the website's hardcoded rain tip). Its mic button opens the assistant.
3. Upcoming actions. Checking a task off updates the screen immediately and reverts if the call fails.
4. Weather card (fake: 32°C sunny; tomorrow 29°C rain; Wed 30°C breezy).
5. Latest alert advisory, with a severity pill and "time ago". Tapping it opens Advisories.
6. Crop health donut and legend. Tapping it opens History.
7. Crop lifecycle stepper (sowing → flowering → pegging → podFill → harvesting). It scrolls sideways and the current stage pulses.
8. Quick actions (Seed, Disease, Knowledge).
9. Recent activity as a list of cards: action, details, formatted time.

The screen supports pull-to-refresh.

### Seed / Disease (`ScanFlowScreen(type)`)
**States:**
1. **Idle:** Take photo and Choose from gallery.
2. **Uploading and analyzing:** a darkened image, corner brackets, pulsing dots, and a gold scan line animating between 5% and 95% of the height over 3 s. It lasts at least 2 s.
3. **Complete:** the results below.

**Upload fields:**

| Screen | title | status | confidence_score |
|---|---|---|---|
| Seed | `seed.mockTitles.t1` | `Healthy` | `94.2` |
| Disease | the equivalent disease title | `High Risk` | `98.1` |

**Seed result:**
- Grade A, 89% germination, 342 seeds.
- Uniformity bars at 85% and 92%.
- Donut chart: Healthy 75, Underdeveloped 12, Damaged 8, Diseased 5. Centre label "75%".
- 3 recommended actions.

**Disease result:**
- Disease, severity (2 of 4 dots) and risk cards.
- The image with 2 terracotta detection boxes.
- Pathology text (`disease.pathologyDesc`, rendered as formatted text).
- An urgent alert.
- A severity line chart (-7d 5, -3d 12, today 35, +3d 58, +7d 82) with a monotone curve and a dashed grid.
- 3 numbered management steps.

**Buttons:** New analysis (reset) and Download PDF, which builds a report with the `pdf` package and shares it.

### History
- **Filter chips:** All, Seed, Disease.
- **List:** cards with the image (an "Image expired" placeholder if it fails to load), status badge, type chip, date and title.
- **Detail bottom sheet:** image, badges, report paragraph, confidence, 3 bullet points, and Download PDF.
- Empty state and pull-to-refresh.

### Advisories
- Cards with a severity-coloured start border and icon, a type pill, and a formatted time.
- Loading, empty state and pull-to-refresh.

### Knowledge Base
- **Search mode:** filters on the device by title and excerpt.
- **Ask AI mode (fake):** a 2 s spinner, then a canned reply picked by keyword:
  - `leaf spot`, `بیماری` or `دھبے` → the disease reply.
  - `seed`, `sow` or `بیج` → the seed reply.
  - Anything else → the general reply.
  - The reply shows in a purple panel.
- **Categories:** chips from `kb.categories`, with counts. Filtering compares the article's `category` against the category names in the current language, as on the website.
- **Article cards:**
  - Category, author, date, title, 2-line excerpt.
  - Opening one shows the detail screen: excerpt as a quote, then the content.
  - Edit and Delete appear only when `article.author == user.name`.
  - Delete asks for confirmation in a bottom sheet.
  - Edit: title, category, excerpt and content, all required.
- There is no Create button for farmers.

### Profile
- Tapping Edit turns the fields into edits:
  - name
  - farm location
  - language
  - timezone (UTC, Asia/Karachi, Asia/Riyadh, Europe/London, America/New_York)
- The identifier is shown read-only, and the user ID is shown.
- Saving calls `PUT /users/me`, then applies the language.
- The email/identifier and cropType edits are left out, because the website never saves them.

### Maintenance
- Calls `GET /admin/system/maintenance/status`.
  - When inactive, the app goes to `/home`.
  - Otherwise it shows "Expected completion" with `end_time`.
- Polls every 60 s, and has Check status and Sign out buttons.

## 8. AI assistant

**Opening and closing:**
- A floating robot button, with a float animation (translateY -8px over 4 s).
- Tapping it, or the daily-tip mic button, opens a full-height bottom sheet.
- It opens automatically 1 s after the first arrival at Home in each app launch.
- Closing the sheet keeps the chat history for the session.

**Header:**
- A "LIVE CHAT" pill and an mm:ss session timer.
- Its own EN/UR switch, which only affects the chat text and bubble direction.
- A close button.

**Robot hero:** tap to toggle recording. It has rotating dashed rings and ping rings while recording, and the label "Record voice" or "Listening…".

**Messages:**
- The greeting, including the user's name.
- User bubbles: text, image (tap for fullscreen) or audio (play/pause).
- Bot bubbles as formatted text.

**Input bar states:**

| State | What the user sees |
|---|---|
| idle | text field; Send appears when text is present; mic, camera and gallery buttons |
| recording | recording in progress |
| reviewing | play or pause with an animated waveform; discard or send |
| reviewingImage | thumbnail (tap for fullscreen); discard or send |

**Permissions:** microphone and camera are requested at first use. If denied, the app shows a toast and does not fake a recording.

**Canned behaviour (`AssistantRepository`):**

| Input | Activity logged (`POST /dashboard/activities`) | Reply |
|---|---|---|
| Text | `('Text Interactions', first 30 chars)` | after 1.5 s: "I am checking your field data…" (EN or UR) |
| Voice | `('Voice Advisory', 'Completed')` | same as text |
| Image | `('Query Copilot', 'Sent an image for analysis')` | "Analyzing image…" at 0.5 s, then the canned nitrogen-deficiency reply at 3.5 s |

Audio and images are never uploaded.

## 9. Error handling

The dio interceptor maps every failure to an `AppException`.

| Failure | App behaviour |
|---|---|
| No connection or timeout | `network`: "Check your internet" |
| 401 on a non-`/auth/*` path | clear storage and go to `/login` |
| 401 on `/auth/*` | a normal `server(detail)` error. `/auth/verify-otp` returns `401 "Invalid OTP"` for a wrong code. |
| 503 | go to `/maintenance` |
| Other 4xx or 5xx | `server(detail)` |

**Per screen:**
- Each screen has four `AsyncValue` states: loading, data, empty and error (with Retry).
- Actions report success or failure with toasts: success, error, warning or info; one at a time; auto-hide after 3 s.
- The website's `alert()` calls become toasts.

## 10. Localization

- `en.json` and `ur.json` are copied from `src/locales`.
- **New keys** for text the website hardcodes in English on farmer screens:
  - lifecycle labels
  - auth panel text
  - maintenance page
  - time-ago
  - timezone labels
  - "Read Article"
  - empty states
  - the admin-role block message
  - camera and permission messages
- Keys missing from `en.json` that the code falls back on (`common.*`, `auth.mockup.*`) are added.
- **Language storage:** the choice is saved in prefs, and the `user.language_preference` from the server overrides it after `GET /users/me` or a profile update.
- **Layout direction:** RTL applies app-wide through the locale. Charts are wrapped in `Directionality(ltr)`.

## 11. Testing

**Unit tests:**
- `api_client`: token header, 401 → logout, 503 → maintenance, error mapping.
- `AuthController`: startup restore, login → OTP → new or existing user, admin blocked, logout.
- Language mapping.
- `date_format` and time-ago.
- The Knowledge Base filter and Ask AI keyword matching.
- `AssistantRepository` timings and logging.

**Widget tests:**
- OTP boxes: advance, backspace and paste.
- Scan flow state changes.
- Task toggling, including the revert on failure.
- Urdu RTL rendering.

**Manual:** on the Android emulator against the local backend:
- the full sign-in flow
- one seed and one disease upload appearing in History
- an article edit
- a profile language switch
- the maintenance redirect

## 12. Build order

Each step ends with a runnable app.

1. Foundations and sign-in:
   - scaffold, theme, config, api client, storage, i18n, router
   - auth screens and the maintenance screen
2. Shell and Home:
   - tab shell, top bar, More tab
   - Dashboard
3. Seed and Disease scan flow, and the PDF report.
4. History and Advisories.
5. Knowledge Base.
6. Profile.
7. AI assistant.
8. Polish: animations, empty states, Urdu review, app icon and name.
