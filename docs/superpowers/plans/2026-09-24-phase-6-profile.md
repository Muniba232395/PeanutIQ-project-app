# Phase 6: Profile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2.

**Goal:** Port `Users.jsx` (the farmer's User Profile) to More → Profile:
- view mode;
- an Edit mode for name, farm location, language and timezone;
- Save calls `PUT /users/me` through `AuthController.updateProfile`. The app language and timezone then change at once.

**Spec:** §7 Profile.

## Global Constraints

Earlier phases apply, plus:

**Header:**
- Title `profile.title` (24 bold, gray-900); subtitle (14, gray-500).
- An **Edit Profile** button: white, gray-300 border, radius 8, 14 weight 500, gray-700, `pencilLine` icon.
- In edit mode it becomes **Save Changes**: forest fill, white. It shows a spinner while saving.

**Card (flat card, padding 24):**
- **Avatar:** 96 px, drawn as `InitialsAvatar`, with a 4px white border and shadow-lg.
- **Name:** 24 bold. In edit mode it's a bottom-border text field.
- **Role:** `profile.roles.<role>` (14, weight 500, gray-500).
- **Info rows** (14, gray-600, gray-400 icons, 20 px):
  - mail + identifier (always read-only; spec: the website never saves email edits);
  - mapPin + farm location, or `profile.unknownLocation`. In edit mode this is a dropdown of `farmRegions`;
  - target + "Peanut", read-only (spec: cropType is never saved);
  - user + "ID: <id>".

**Preferences footer:**
- Sand fill, slate-200 top border.
- Heading `profile.accountPreferences` (14 bold, slate-700, uppercase).
- **Language row:** `profile.languagePreference` plus `languageDescription`, and a pill button:
  - disabled: sand at 75%; editable: white;
  - slate-200 border, radius 12, 14 weight 500;
  - the value is capitalised (English / Urdu). Its menu offers `profile.english` / `profile.urdu`.
- **Timezone row:** `profile.app.timezoneTitle` and `timezoneDesc` (new keys; the website hardcodes them in English), with the same pill. Menu labels (`profile.app.tz.*`):

  | Key | Zone |
  |---|---|
  | `utc` | UTC (Default) |
  | `karachi` | Pakistan (PKT) |
  | `riyadh` | Arabia (AST) |
  | `london` | Greenwich (GMT) |
  | `newYork` | Eastern (EST) |

  The value shows the raw tz name, as on the website.

**Save:**
- Sends `{name (trimmed), farm_location, language_preference ('english'|'urdu'), timezone}`.
- **Success:** leave edit mode and show a success toast `profile.app.saved`.
- **Failure:** an error toast `auth.app.saveFailed` (the website used `alert()`); stay in edit mode.
- **Empty name:** Save is disabled. The website allows it, but an empty name breaks greetings.
- **Cancel:** Android back while editing leaves edit mode without saving (no website equivalent; needed on mobile).

**New keys:**

| Key | en | ur |
|---|---|---|
| `profile.app.timezoneTitle` | Time Zone | ٹائم زون |
| `profile.app.timezoneDesc` | Sets how dates and times are displayed to you on your dashboard. | آپ کے ڈیش بورڈ پر تاریخیں اور اوقات کیسے دکھائے جائیں۔ |
| `profile.app.saved` | Profile updated | پروفائل اپ ڈیٹ ہو گئی |
| `profile.app.tz.utc` | UTC (Default) | UTC (ڈیفالٹ) |
| `profile.app.tz.karachi` | Pakistan (PKT) | پاکستان (PKT) |
| `profile.app.tz.riyadh` | Arabia (AST) | عرب (AST) |
| `profile.app.tz.london` | Greenwich (GMT) | گرینچ (GMT) |
| `profile.app.tz.newYork` | Eastern (EST) | مشرقی (EST) |

## Review Focus

1. **Saving Urdu.** Expected: the whole app switches to Urdu right after saving, and stays Urdu after a relaunch. Test: "saving urdu switches the app".
2. **Changing the timezone.** Expected: dashboard times re-render in the new zone. Test: "timezone change reformats activity time".
3. **The save fails** (offline). Expected: the form stays in edit mode with the values kept, and an error toast shows. Test: "save failure keeps edits".
4. **The name is cleared.** Expected: Save is disabled. Test.
5. **Back while editing.** Expected: edit mode is cancelled and the original values are restored. Test.

### Task 1: Profile screen

**Files:** `lib/features/profile/profile_screen.dart`, `tool/translations/phase6.json`; route `/more/profile`.

**Tests (`test/features/profile/profile_screen_test.dart`):**
- "shows name, role, email, location, crop and id";
- "edit and save sends the website fields";
- "saving urdu switches the app";
- "timezone change reformats activity time";
- "save failure keeps edits";
- "empty name disables save";
- "back cancels editing";
- "fits 360x640 at 1.5x in Urdu".

### Task 2: Emulator check

Screenshots of view and edit modes; save a language change and see it apply.
