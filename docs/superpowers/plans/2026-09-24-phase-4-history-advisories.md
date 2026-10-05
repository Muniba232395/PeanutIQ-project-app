# Phase 4: History and Advisories — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2.

**Goal:** Port `HistoryReports.jsx` and `Advisories.jsx` as the More → History and More → Advisories screens.

**Architecture:**
- **Data:** `HistoryRepository` (`GET /scans/`) returns `ScanRecord`s. Advisories reuse `AdvisoriesRepository.fetch()`.
- **State:** FutureProviders keyed on the user id, as in Phase 2.
- **Detail:** the History detail is a bottom sheet. The website uses a modal; the spec says bottom sheet.
- **Download PDF:** builds a History report through the Phase 3 report service.
- **Scan image addresses:** the backend stores `image_url` as `http://127.0.0.1:8000/uploads/<file>`. On a phone, `127.0.0.1` is the phone itself, so the address is rewritten to the configured API server's origin.

**Spec:** §7 History, Advisories; §9.

## Global Constraints

Phases 1–3 apply, plus:

**Image addresses:** `resolveMediaUrl(url, apiBaseUrl)`. When the url's host is `127.0.0.1` or `localhost`, replace its scheme, host and port with those of `apiBaseUrl`, keeping the path and query. Other urls are unchanged.

**History list:**
- **Filters:** All / Seed Intelligence / Disease Intelligence, as rounded-full chips (14, weight 500). Active: forest fill, white text. Inactive: white, slate-600 text, slate-200 border.
- **Filtering:** on the device, by `type`.
- **Cards:** one column (the website's `grid-cols-1` at phone width); flat-card.
  - **Photo:** 160 tall on slate-100.
    - If it fails to load: `scanSearch` icon (32, slate-400 at 50%) and "IMAGE EXPIRED" (10 bold).
    - A status badge at the top end: white at 90%, a border, a dot and bold 12 text.
  - **Body** (padding 20):
    - a type chip: forest text, sand fill, earth border, bean or scanSearch icon;
    - a calendar icon and the date;
    - the title: 18 bold slate-900, at most 2 lines;
    - a divider (slate-100);
    - a "Download PDF" button: forest text, sand fill, earth border, radius 8.
- **Status colours:**

  | Status | Text | Border | Dot |
  |---|---|---|---|
  | Healthy | forest | emerald-200 `A4F4CF` | forest |
  | High Risk | rose-700 `C70036` | rose-200 `FFCCD3` | rose-500 |
  | Moderate | amber-700 | amber-200 | amber-500 |
  | other | slate-700 | slate-200 | slate-400 |

  Status labels: `history.statusHealthy`, `statusHighRisk`, `statusModerate`. Any other status shows the Moderate label, as on the website.
- **Dates:** `M/d/yyyy`; a zone-less `created_at` is read as local time (`new Date(...)`).
- **Empty:** a dashed flat card with a `filter` icon (48, slate-300), `history.noRecords` and `history.tryFilters`.
- **Loading and errors:** loading, error with Retry, pull-to-refresh.

**History detail (bottom sheet, 90% height, scrolls):**
- The photo at 192 px with the expired fallback. A "Download PDF" pill (forest at 90%, white bold) at the top start; a close button (white at 80%, circle) at the top end.
- Chips: type and date; the status badge (14 bold).
- The title: 24 bold.
- The paragraph: `reportParagraph1 <strong>status</strong> reportClassification`.
- Bullets: `confidenceScore <strong>NN%</strong>`, then `reportListItem1..3`.

**History PDF:** `buildHistoryReport(record, t, english, imageBytes, generatedAt, fonts)`.
- **Contents:** title, type, date, status, the paragraph and the bullets.
- **Photo:** fetched with `ApiClient.getBytes(resolvedUrl)`; left out if the fetch fails.
- **File name:** `peanutiq-history-<id first 8>-<stamp>.pdf`.

**Advisories:**
- **Data:** `GET /dashboard/advisories` with no query (the backend default is 5, like the website).
- **Card:** white, radius 12, shadow-sm, padding 20, a 4px start border by severity:

  | Severity | Border | Icon |
  |---|---|---|
  | high | red-500 | triangleAlert, red-500 |
  | medium | yellow-500 | info, yellow-500 |
  | low / other | blue-500 | info, blue-500 |

- **Content:**
  - title: 18 bold charcoal;
  - time chip: slate-100, 12 bold slate-500, clock icon, `formatDate(created_at, user.timezone)`;
  - type pill: `type.toUpperCase()`, untranslated as on the website. alert is red-50/red-700; other types blue-50/blue-700 `1447E6`;
  - message: 14 weight 500, slate-600.
- **Empty:** a white card with a leaf icon (48, forest at 50%), `advisories.emptyTitle` and `emptyDesc`.
- **Loading:** a spinner. Errors show Retry. Pull-to-refresh.

**New keys:**

| Key | en | ur |
|---|---|---|
| `history.imageExpired` | Image Expired | تصویر دستیاب نہیں |
| `history.app.downloadFailed` | Could not create the PDF. | پی ڈی ایف نہیں بن سکی۔ |

## Review Focus

1. **The backend returns the image at `127.0.0.1`.** Expected: the phone loads it from the real server. Test: `media_url_test`.
2. **The image no longer exists** (404). Expected: "Image Expired" is shown, not a broken image or crash. Test: "failed image shows Image Expired".
3. **A new scan was just made.** Expected: History shows it on the next visit, with no stale cache. Test: "history refetches after a scan completes" (Phase 3's controller invalidates the history provider on complete).
4. **No advisories.** Expected: the empty card, not a blank screen. Test: "advisories empty state".
5. **The PDF's image fetch fails.** Expected: the PDF is still shared, without the image. Test: "history PDF without image".

---

### Task 1: Data

**Files:**
- `lib/core/media_url.dart`
- `lib/core/api_client.dart`: add `getBytes(String absoluteUrl)` returning `Future<Uint8List>`.
- `lib/features/history/data/scan_record.dart`
- `lib/features/history/data/history_repository.dart`
- `lib/features/history/history_providers.dart`: `historyProvider`
- `lib/features/advisories/advisories_providers.dart`: `advisoryListProvider`
- `lib/features/scan/scan_flow_controller.dart`: invalidate `historyProvider` and `activitiesProvider` on complete, because the backend logs an activity per scan.
- Tests: `test/core/media_url_test.dart` and `test/features/history/history_data_test.dart`.

**Tests:**
- `media_url`: rewrites `http://127.0.0.1:8000/uploads/a.jpg` with base `http://10.0.2.2:8000/api/v1` to `http://10.0.2.2:8000/uploads/a.jpg`; the same for localhost; a base with https and another port gives `https://api.example.com/uploads/a.jpg`; other hosts are unchanged; an empty value stays empty.
- `ScanRecord.fromJson`: parses fields; `confidence_score` can be int or double; `imageUrl` is resolved.
- `historyProvider` requests `GET /scans/`.
- "history refetches after a scan completes": the request count goes up after `start()` completes.
- `advisoryListProvider` sends no query.

### Task 2: History screen

**Files:** `lib/features/history/history_screen.dart`, `widgets/scan_record_card.dart`, `widgets/scan_detail_sheet.dart`, `widgets/status_badge.dart`, `lib/features/report/history_report.dart`; route `/more/history`.

**Tests (widget):**
- "lists records with status badges and type chips".
- "filter chips narrow the list".
- "empty state": no records, or the filter matches nothing.
- "failed image shows Image Expired": the image url 404s via a fake HttpOverrides, or an `errorBuilder` test through a fake `imageProvider` hook.
- "tapping a card opens the detail sheet with paragraph and bullets".
- "Download PDF shares peanutiq-history-*.pdf" (from the card and from the sheet).
- "history PDF without image": `getBytes` fails and it is still shared.
- "fits 360x640 at 1.5x in Urdu".

### Task 3: Advisories screen

**Files:** `lib/features/advisories/advisories_screen.dart`; route `/more/advisories`.

**Tests:** "lists advisories with severity styling and formatted time"; "advisories empty state"; "error shows Retry"; "fits small screen in Urdu".

### Task 4: Emulator check

Extend the mock API with `GET /scans/` (two records, one image served by the mock at a `127.0.0.1` url) and `/uploads/*`. Screenshots of History, the detail sheet and Advisories.
