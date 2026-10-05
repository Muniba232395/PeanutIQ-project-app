# Phase 8: Polish, Demo Mode and APK — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2.

**Goal:**
- **Demo mode** (user request, 2026-09-24: "app should have mock data"). A build flag makes the app run entirely on built-in mock data, with no backend.
- **Offline fonts:** bundled into the app.
- **App icon and launch screen:** PeanutIQ's logo.
- **The deferred minor fixes.**
- **An Urdu and assistant review on the emulator.**
- **A release APK** built in demo mode.

**Architecture:**
- **Demo mode:** `demoMode = bool.fromEnvironment('DEMO_MODE')`.
  - When on, `httpAdapterProvider` returns `DemoBackendAdapter`. This is an in-process Dio adapter that answers every endpoint the app uses from seeded, in-memory data, with a small delay.
  - Everything above the adapter (repositories, controllers, screens) is unchanged, so demo mode exercises the real app code.
- **Fonts:**
  - Static TTFs from Fontsource (jsDelivr), declared in `pubspec` as the families `Inter`, `PlusJakartaSans` and `NotoNastaliqUrdu`.
  - The `google_fonts` package is removed. The English theme falls back to Nastaliq for Urdu text; the Urdu theme falls back to Inter for Latin text.
  - The PDF uses the bundled Inter, and Noto Naskh Arabic for Urdu. `PdfGoogleFonts` is removed, so reports work offline and bold works.

## Demo backend contract

- **Code:** any email with code `123456` signs in; any other code returns `401 {"detail":"Invalid OTP"}`.
- **New emails:** get a new farmer with no name or farm location, so profile setup appears.
- **Pre-seeded account:** `demo@peanutiq.app` is a full farmer: "Ali Khan", Chakwal, Asia/Karachi.

| Endpoint | Behaviour |
|---|---|
| `GET/PUT /users/me` | Returns the signed-in user. PUT merges the fields. |
| `GET /dashboard/activities?limit` | Newest first. Scans and assistant logs add entries (`POST /dashboard/activities`). |
| `GET /dashboard/advisories?type&limit` | Four seeded advisories (alert high, tip low, weather medium, alert medium); default limit 5. |
| `GET /dashboard/crop-profile` | pegging; 72 / 18 / 10. |
| `GET/PUT /dashboard/actions(/id)` | Three tasks; toggles persist. |
| `GET /scans/` | Newest first. |
| `POST /scans/` | Parses the multipart body, saves the photo to the app's temp folder, and adds a record with `image_url = file://…`. It logs "Seed Quality Scan" or "Disease Analysis". |
| `GET /knowledge/articles` | Five articles across the five English categories. |
| `GET /admin/system/maintenance/status` | `{active: false}` |
| Unknown paths | 404 |

**Seeded scan images:**
- One uses a bundled asset (`asset:///assets/images/demo_field.jpg`).
- One uses a missing file, to show "Image Expired".
- `ScanNetworkImage` and `ApiClient.getBytes` (through the adapter) understand the `asset:` and `file:` schemes.

**Demo hint:** in demo mode the OTP screen shows `auth.app.demoHint`:

| Language | Text |
|---|---|
| en | Demo mode: use code 123456 |
| ur | ڈیمو موڈ: کوڈ 123456 استعمال کریں |

## Deferred minors (from the Phase 1 review) now fixed

1. **Known backend `detail` strings are translated:** OTP expired, No active OTP found, User not found, Failed to send OTP email, Not authorized…, System under maintenance. The keys are `common.serverErrors.*`, and `describeError` checks them before showing the raw text.
2. **Back from Signup returns to Login:** Login → Signup uses `push`, and Signup → Login pops when possible.
3. **`android:allowBackup="false"`** on the application, so the stored token isn't restored onto another device.
4. **PDF bold in fallback fonts:** fixed by the bundled fonts.
5. **Latin text in Urdu uses Inter:** through the font fallback.
6. **An error shown before a language switch stays in the old language** (all forms). Deferred again: the forms store the error text rather than the key. Low impact, since the farmer can just retry.

## Icon and launch screen

- A 1024 px icon made with PIL from the Lucide `bean` and `leaf` glyphs: a white bean, a lime leaf (`#A3D977`), on forest (`#07571C`).
- An adaptive-icon foreground on a transparent background.
- A launch screen with a sand background and the logo in the centre.
- Produced with `flutter_launcher_icons` and `flutter_native_splash` (dev dependencies).

## Tasks

1. **Demo backend**, with `test/core/demo_backend_test.dart`:
   - the login flow;
   - advisories filtered and limited;
   - action toggles persist;
   - profile updates persist;
   - multipart upload parsed into a record;
   - asset bytes served;
   - a widget test: the demo app signs in and the dashboard shows the seeded data.
2. **Bundled fonts** and the PDF font switch. Tests: the theme uses the bundled families; the PDF builds with loaded fonts.
3. **Deferred minors 1–3**, with tests.
4. **Icon and launch screen.** Checked with a build and a screenshot.
5. **Emulator review** in demo mode, English and Urdu, covering every screen and the assistant. Fix what's found, test-first.
6. **Release APK:** `flutter build apk --release --dart-define=DEMO_MODE=true`; README; push.
