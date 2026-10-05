# Phase 3: Seed and Disease Scans — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2: files, interfaces and concrete tests; code is written test-first.

**Goal:** Port `SeedIntelligence.jsx` and `DiseaseIntelligence.jsx` as one shared flow. The Seed and Disease tabs each run it:
1. Pick a photo (camera or gallery).
2. Upload it to `POST /scans/` with the website's fixed fields.
3. Show the scanning animation for at least 2 s.
4. Show the website's fixed results, with charts.

Both result screens offer "New Analysis" and "Download Report". Download Report creates a real PDF and opens Android's share sheet, replacing `window.print()`.

**Architecture:**
- **`ScanKind { seed, disease }`** holds the per-kind configuration: upload fields, translation prefix, colours.
- **`ScanFlowController`:** a Riverpod family notifier keyed by kind. State goes idle → analyzing(image) → complete(image).
- **Device and network work** sits behind small interfaces so tests use fakes:
  - `PhotoPicker` wraps image_picker;
  - `ReportSharer` wraps printing's share;
  - `ScanRepository` does the multipart upload through `ApiClient.postMultipart`.
- **Results:** `ScanAnalysisRepository` returns the website's fixed numbers, the fidelity rule's fake part.

**Spec:** §7 Seed / Disease, §9.

## Global Constraints

Phase 1 and 2 constraints apply, plus:

**Upload fields (multipart `POST /scans/`):**

| Field | Seed | Disease |
|---|---|---|
| `type` | `Seed Intelligence` | `Disease Intelligence` |
| `title` | `Seed Quality Analysis` | `Late Leaf Spot Detection` |
| `status` | `Healthy` | `High Risk` |
| `confidence_score` | `94.2` | `98.1` |

The title is always English: the website's `mockTitles` key is missing in both languages, so it falls back to English.

**If the upload fails:** show the results anyway, as the website does, plus a warning toast `scan.app.uploadFailed`.

**Timing:** analyzing lasts for the upload plus 2 s, as the website does (`await` the upload, then `setTimeout(2000)`).

**Fixed seed results (from SeedIntelligence.jsx):**
- Grade A.
- Germination 89%.
- 342 seeds.
- Size variance "Low (4.2%)" (85% bar); colour consistency "High (92%)" (92% bar).
- Donut: Healthy 75 `#22c55e`, Underdeveloped 12 `#eab308`, Damaged 8 `#f97316`, Diseased 5 `#ef4444`. Inner 60, outer 80, 5° padding; centre "75%" + HEALTHY.
- Three action rows:

  | Row | Background | Border | Icon |
  |---|---|---|---|
  | Proceed | green-50 | green-200 (`B9F8CF`) | forest check |
  | Manual | red-50 | red-500 | red triangle |
  | Save | sand | gray-200 | charcoal file |

**Fixed disease results (from DiseaseIntelligence.jsx):**

| Card | Border and top strip | Content |
|---|---|---|
| Detected | terracotta | red-50 confidence pill |
| Severity | orange-400 | text orange-500 (`FF6900`); 2 of 4 dots |
| Risk | red-500 | red-50 circle with a triangle |

- The photo with 2 terracotta boxes (`top 25% left 25%, 25%×25%` and `bottom 33% right 25%, 20%×20%`).
- Pathology text rendered from its HTML: only `<strong>` and `<span dir="ltr">` occur, so a tiny parser is enough (no flutter_html).
- An urgent alert card.
- The line chart:
  - points: −7 5, −3 12, today 35, +3 58, +7 82;
  - line: chart terracotta `#C05A3B`, width 3, dots r6;
  - dashed horizontal grid `#E8E4D9`; axis text 12 `#4A4A4A`.
- Three numbered recommendations.

**Idle card:**
- **Border:** dashed 2px. Earth for Seed; terracotta at 50% for Disease.
- **Icon:** a circle 80, sand fill, 1px border (forest or terracotta) holding the cloud-upload icon in the same colour.
- **Title:** 20 bold.
- **Description:** charcoal at 70%.
- **Buttons (mobile change):** "Camera" and "Gallery" primary buttons, using the existing keys `seed.captureCamera`/`seed.selectGallery` and the disease equivalents. They replace drag-and-drop.

**Analyzing view:**
- A panel holding a rounded (24) box, 224 tall, `forest/90`, with the photo at 50% opacity.
- Four white-80 corner brackets: 48 px, 4px stroke, 16 px radius, 24 px inset.
- Four pulsing white capsules (12×20), plus the gold scan line with 64 px gold/30 gradients, animating top 5% ↔ 95% over 3 s.

**Header:** `seed.title` / `disease.title` (24 bold) and the subtitle (14, charcoal at 70%).

**Complete-state buttons:**
- "New Analysis": sand fill, 2px earth border, radius 8, 14 bold, `refreshCcw` icon.
- "Download Report": the primary button with a `download` icon.

**PDF report (`pdf` + `printing`):**
- The page is A4 with 1 cm margins (the website's print CSS).
- **Contents:**
  - title and subtitle;
  - "Generated on <formatDate(now, user tz)>";
  - the photo;
  - the key results as text and simple bars (no chart images);
  - the recommendations.
- **Fonts:** Noto Sans, or Noto Naskh Arabic for Urdu, fetched with `PdfGoogleFonts`.
- If the fonts can't be fetched, the report falls back to English and the built-in Helvetica. Nastaliq is not supported by the pdf package; Naskh is readable Urdu.
- **File name:** `peanutiq-seed-report-YYYYMMDD-HHMM.pdf` (and `-disease-`).

**Errors:**
- Camera unavailable or denied: toast `scan.app.cameraUnavailable`.
- Cancelling the picker: stays idle, no toast.

## Review Focus

1. **Farmer cancels the camera or gallery.** Expected: they stay on the upload card, with no error and no request. Test: "cancelled pick stays idle".
2. **Upload fails** (offline). Expected: results still appear, plus a warning toast. Test: "upload failure still shows results and warns".
3. **The farmer leaves the tab mid-analysis and comes back.** Expected: the flow continues and shows the results; switching tabs doesn't reset it. Test: "analysis survives switching tabs".
4. **Camera permission denied.** Expected: a toast, and the screen stays idle. Test: "camera error shows toast".
5. **Urdu report.** Expected: PDF generation doesn't crash when fonts are unavailable offline; it falls back. Test: `report_builder_test` "falls back when fonts fail".

---

### Task 1: Scan domain, upload and flow controller

**Files:**
- `pubspec.yaml`: add `image_picker`, `pdf`, `printing`.
- `lib/core/api_client.dart`: add `postMultipart(String path, {required Map<String, String> fields, required String filePath, String fileField = 'file'})`.
- `lib/features/scan/scan_kind.dart`: `enum ScanKind {seed, disease}` with `apiType`, `uploadTitle`, `uploadStatus`, `confidence`, `prefix` ('seed'|'disease').
- `lib/features/scan/data/scan_repository.dart`: `upload(ScanKind, String imagePath)`.
- `lib/features/scan/data/scan_analysis_repository.dart`: `SeedResult`, `DiseaseResult` (constants above).
- `lib/features/scan/device/photo_picker.dart`:
  - `enum PhotoSource {camera, gallery}`;
  - `abstract interface class PhotoPicker { Future<String?> pick(PhotoSource) }`;
  - `ImagePickerPhotoPicker`, with `imageQuality: 85` and `maxWidth: 2048` (smaller uploads);
  - `photoPickerProvider`.
- `lib/features/scan/scan_flow_controller.dart`:
  - `ScanFlowState {phase, imagePath}` with `enum ScanPhase {idle, analyzing, complete}`;
  - `scanFlowProvider` (family by kind, not autoDispose, so it survives tab switches);
  - methods `start(PhotoSource)` (returns a `ScanStartResult`: cancelled, ok, uploadFailed or pickFailed), `reset()`;
  - `analysisDelayProvider` (Duration, default 2 s; tests use it).
- `tool/translations/phase3.json`:

  | Key | en | ur |
  |---|---|---|
  | `scan.app.uploadFailed` | Couldn't save this scan to your history. | یہ اسکین آپ کی ہسٹری میں محفوظ نہیں ہو سکا۔ |
  | `scan.app.cameraUnavailable` | Could not open the camera or gallery. | کیمرہ یا گیلری نہیں کھل سکی۔ |
  | `scan.app.generatedOn` | Generated on | تیار کردہ |
  | `scan.app.shareFailed` | Could not create the report. | رپورٹ نہیں بن سکی۔ |

- Tests: `test/features/scan/scan_flow_test.dart` and `api_client_test` (multipart).

**Tests:**
- "postMultipart sends fields and file": the request data is `FormData` with the 4 fields and one file named `file`; the Authorization header is set.
- "seed upload sends the website's fields": `{type: Seed Intelligence, title: Seed Quality Analysis, status: Healthy, confidence_score: 94.2}`.
- "disease upload sends the website's fields" (the disease values).
- "cancelled pick stays idle": the picker returns null, the state stays idle, no request, and the result is cancelled.
- "start goes analyzing then complete after the delay": with the delay at 50 ms, the state is analyzing immediately (with the image path), then complete.
- "upload failure still completes and reports uploadFailed".
- "picker error returns pickFailed and stays idle".
- "reset returns to idle".

### Task 2: Scan screens

**Files:**
- `lib/features/scan/scan_screen.dart`: `ScanScreen(kind)`. The header, then a switch on the phase; complete-state buttons.
- `lib/features/scan/widgets/`:
  - `upload_card.dart`
  - `analyzing_view.dart`
  - `seed_results.dart`
  - `disease_results.dart` (includes the fl_chart LineChart)
  - `rich_html_text.dart`: a `<strong>`/`<span dir>` parser that returns a `Text.rich`
  - `result_card.dart`: a flat card with a 14 bold uppercase forest title and an optional icon
- `lib/core/router.dart`: the Seed and Disease branches use `ScanScreen`.
- Test: `test/features/scan/scan_screen_test.dart`, using a fake picker (returns `test/fixtures/leaf.png`), a zero analysis delay, and FakeAdapter `POST /scans/` 201.

**Tests:**
- "Seed tab shows the upload card with Camera and Gallery".
- "choosing a photo shows the scanning view, then seed results": "Analyzing Seeds..." first; after the delay, the grade "A", "89", "342", the classification labels, "75%" and the three action titles.
- "disease results": "Early Leaf Spot", "HIGH RISK", the pathology text with "Cercospora arachidicola" in bold, a `LineChart` present, "Chemical Control".
- "New Analysis returns to the upload card".
- "upload failure still shows results and warns" (toast text).
- "camera error shows toast": the picker throws, and the toast appears.
- "analysis survives switching tabs": start, switch to Home, back to Seed; the results show.
- "rich_html_text parses strong and ltr spans" (unit): the bold span text is correct and the plain text is kept.
- "Urdu disease results fit 360x640 at 1.5x".

### Task 3: PDF report

**Files:**
- `lib/features/report/report_builder.dart`: `Future<Uint8List> buildScanReport({required ScanKind kind, required Translations t, required Uint8List? imageBytes, required String generatedAt, ReportFonts? fonts})`.
- `lib/features/report/report_fonts.dart`: `loadReportFonts(String languageCode)` returns `ReportFonts?` (null on failure).
- `lib/features/report/report_sharer.dart`: `ReportSharer.share(Uint8List bytes, String filename)`, implemented with `Printing.sharePdf`; plus a provider.
- `lib/features/scan/scan_screen.dart`: Download Report builds and shares. On failure, a toast `scan.app.shareFailed`.
- Tests: `test/features/report/report_builder_test.dart` and the screen test.

**Tests:**
- "seed report is a PDF containing the key results": the bytes start with `%PDF`. The test fonts are null, so Helvetica is used and the content is English.
- "disease report builds with an image".
- "falls back when fonts fail": in Urdu with null fonts it still builds, using English strings.
- "Download Report shares a PDF named peanutiq-seed-report-*.pdf": the fake sharer receives the bytes and the filename.

### Task 4: Emulator check

Use a release build against the throwaway mock API (adds `POST /scans/`):
1. Pick a gallery photo (push a sample image to the emulator first).
2. Watch the scanning animation.
3. Check the results.
4. Tap Download Report; the share sheet appears.

Screenshots of Seed and Disease in English and Urdu.
