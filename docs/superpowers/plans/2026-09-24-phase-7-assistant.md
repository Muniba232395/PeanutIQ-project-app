# Phase 7: AI Assistant (FloatingAgent) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2.

**Goal:** Port `FloatingAgent.jsx` to the farmer shell:
- a floating robot button;
- a forest-green chat panel with:
  - a live-chat header, session timer, its own EN/UR switch and close;
  - the big robot, which you tap to record;
  - chat bubbles for text, photo and voice messages;
  - an input bar with text, mic, camera and gallery, plus review states for a recording or a photo;
  - a fullscreen photo preview;
- the website's canned replies and activity logging.

**Rulings:**
- **Floating panel, not a bottom sheet.** The spec said "full-height bottom sheet", but on a phone the website shows a floating panel: `90vw` wide, `75vh` tall (max 600), anchored at the bottom end, radius 32. The app should match the website, so the panel is copied.
- **Camera uses the system camera (image_picker)**, not an in-panel live view. Flutter's `camera` plugin would add native setup for no user benefit; the photo ends in the same review state.
- **Microphone permission denied:** show a toast, don't fake a recording (spec §8). The website fakes one.
- **Audio playback:** a play/pause bubble instead of the browser's `<audio controls>`.
- **Auto-open:** 1 s after the shell first appears, once per launch (spec §8). The website opens on every page load.
- **Page change:** closes the panel and resets its language to EN, as the website does. Tab switches and pushes count as page changes.

**Architecture:**
- **`AssistantController`** (`Notifier<AssistantState>`) holds everything:
  - `open`, `language`, `messages`, `input` state (idle/recording/reviewingAudio/reviewingImage), `previewImagePath`, `audioPath`, `playingPath`.
  - The canned replies run through `Future.delayed`. The delays are provided by `assistantTimingProvider`, so tests can shorten them.
- **Device access** sits behind interfaces:
  - `VoiceRecorder` (the `record` package: hasPermission, start to a temp .m4a, stop returns the path);
  - `AudioPlayback` (`just_audio`: play(path), pause, a completion stream);
  - `PhotoPicker` (from Phase 3).
- **Logging:** `POST /dashboard/activities` through `DashboardRepository.logActivity`, then `activitiesProvider` is invalidated.
- **UI:** `FloatingAssistant` sits in the `AppShell` body `Stack`. `assistantLauncherProvider` (Phase 2, the tip's mic) opens it. The shell passes the current location, and a change closes the panel.

## Global Constraints

Earlier phases apply, plus:

**Assistant text:** stored under `assistant.*` in both translation files. It is picked by the *assistant's own* language, not the app's.

| Key | en | ur |
|---|---|---|
| `liveChat` | LIVE CHAT | لائیو گفتگو |
| `recordVoice` | Record Voice | آواز ریکارڈ کریں |
| `listening` | Listening... | سن رہا ہوں... |
| `liveListening` | LIVE LISTENING | لائیو سن رہا ہے |
| `reviewReady` | Recording Ready | ریکارڈنگ تیار ہے |
| `langButton` | EN | اردو |
| `placeholder` | Type your message... | یہاں لکھیں... |
| `greeting` | Welcome {{name}}! I am your smart agricultural assistant. How can I help you today? | خوش آمدید {{name}}! میں آپ کا سمارٹ زرعی اسسٹنٹ ہوں۔ آج میں آپ کی کیا مدد کر سکتا ہوں؟ |
| `defaultName` | Farmer | کسان |
| `analyzingImage` | Analyzing image... | تصویر کا تجزیہ کر رہا ہوں... |
| `imageResult` | I can see signs of nitrogen deficiency in the crop. You should apply Urea fertilizer immediately. | میں دیکھ سکتا ہوں کہ فصل میں نائٹروجن کی کمی کے آثار ہیں۔ آپ کو فوراً یوریا کھاد کا استعمال کرنا چاہیے۔ |
| `textReply` | I am checking your field data. Based on current crop conditions, it is optimal to... | میں آپ کے کھیت کا ڈیٹا چیک کر رہا ہوں۔ فصل کی موجودہ حالت کے مطابق، یہ بہترین ہے... |
| `voiceSent` | 🎤 Voice message sent | 🎤 آواز کا پیغام بھیجا گیا |
| `close` | Close | بند کریں |
| `cameraError` | Unable to access camera. | کیمرہ کھولنے میں مسئلہ درپیش ہے |
| `micDenied` | Microphone permission is needed to record. | ریکارڈنگ کے لیے مائیکروفون کی اجازت درکار ہے۔ |

The greeting's `{{name}}` is drawn bold in gold (`#f0c169`).

**Message rendering (as on the website):**
- The greeting and the image replies are stored as *keys*, so they switch language with the toggle.
- Text replies are stored as text, in the language active when they were sent.

**Canned behaviour and timing:**

| Input | Logged activity | Reply |
|---|---|---|
| Text | `('Text Interactions', text ≤30 chars, or first 30 + '...')` | the user bubble, then `textReply` at +1.5 s |
| Voice | `('Voice Advisory', 'Completed')` | an audio bubble (`voiceSent` + player), then `textReply` at +1.5 s |
| Photo | `('Query Copilot', 'Sent an image for analysis')` | a photo bubble; an AI `analyzingImage` bubble at +0.5 s, which becomes `imageResult` at +3.5 s |

**Styles:**

- **Launcher:** 48 px, forest circle, 2px white/20 border, big shadow, `RobotFace` at 40, float animation. It sits 16 px from the bottom end of the body, above the tab bar.
- **Panel:**
  - `min(90% width, …)`, height `min(75% height, 600)`, bottom-end with a 16 px margin.
  - Forest fill, radius 32, 1px white/20 border, shadow `0 20 50 rgba(0,0,0,.5)`.
  - A transparent full-screen barrier closes it on an outside tap.
- **Header:**
  - The live pill: gold/10 fill, gold 10 bold text, a pulsing gold dot.
  - The timer: `mm:ss`, earth/70, 10 px monospace, counting up every second from when the shell appeared.
  - The language button: white/10 fill, white/30 border, earth text, globe icon.
  - The close X: earth.
- **Robot row:**
  - The robot: 48 px, white/5 fill, white/20 border, `RobotFace` 28.
  - Rings: a 64 px dashed white/10 ring spinning over 10 s; a 96 px white/5 ring; a 128 px ring with gold/30 top and bottom, spinning in reverse over 15 s.
  - While recording: gold/20 fill, gold/50 border, scaled 1.1, plus two gold ping rings.
  - The label: `recordVoice`, or `listening` in gold (pulsing) while recording.
- **Chat area:**
  - Black/15 fill, radius 32 at the top, white/10 top border, padding 24/20, a 16 px gap between bubbles.
  - User bubble: earth fill, forest bold 14, radius 24 with the top-end corner 4, max 85% width. A photo inside is at most 200 wide, radius 12, and opens fullscreen on tap.
  - AI bubble: black/20 fill, white/20 border, sand text 14, line height 1.6, radius 24 with the top-start corner 4, max 90% width.
- **Input bar** (forest, white/10 top border, padding 16/12):
  - **Idle:** a text field (black/30 fill, white/10 border, radius 24, white text, white/40 hint); a 40 px gold circular send button appears when there is text.
  - **Action pill** (black/20 fill, white/20 border, radius 40):
    - mic: 48, sand fill, forest icon;
    - while recording the mic becomes gold with a square stop icon;
    - camera and gallery: 40, black/20 fill, white/20 border, earth icons; hidden while recording;
    - the middle shows a dot, `liveListening` (gold while recording, earth otherwise) and a 15-bar gold waveform: 20% opacity when idle, animating at 100% while recording;
    - the end has a small robot (48, white/10) that closes the panel.
  - **Review pill** (white/10 fill, white/30 border, radius 40):
    - discard: 56, terracotta fill, sand trash icon;
    - the middle shows a photo thumbnail (48 tall, radius 8, fullscreen on tap), or a play/pause button (32, forest fill, gold icon) with `reviewReady` and a waveform while playing;
    - send: 56, gold fill, forest icon.
- **Fullscreen photo:** black/90 over the panel, contained, with an X.

## Review Focus

1. **The farmer switches tab with the panel open.** Expected: it closes and the language resets to EN. The chat history is kept, as on the website, where the component stays mounted. Test.
2. **The panel is closed while a reply is pending.** Expected: the reply still arrives in the history; no crash. Test.
3. **Mic permission denied.** Expected: a toast and no recording state. Test.
4. **Sending when activity logging fails** (offline). Expected: the chat works normally; the logging error is ignored, as on the website. Test.
5. **A long message and Urdu at 1.5× on a small phone.** Expected: no overflow; RTL bubbles. Test.

---

### Task 1: Controller and devices

**Files:**
- `pubspec`: add `record`, `just_audio`, `path_provider`.
- Android manifest: `RECORD_AUDIO`.
- `lib/features/assistant/device/voice_recorder.dart`: interface plus `RecordVoiceRecorder`.
- `lib/features/assistant/device/audio_playback.dart`: interface plus `JustAudioPlayback`.
- `lib/features/assistant/assistant_controller.dart`: `AssistantState`, `ChatMessage` (sender, kind text/image/audio, text?, key?, path?), and the controller methods:
  - `open()`, `close()`, `toggleLanguage()`, `resetLanguage()`;
  - `sendText(String)`, `toggleRecording()` (returns false if permission is denied), `discard()`, `sendReview()`;
  - `pickPhoto(PhotoSource)` (returns false on error), `togglePlayback(String path)`.
- `lib/features/dashboard/data/dashboard_repository.dart`: `logActivity(action, details)`.
- `tool/translations/phase7.json`.
- Test: `test/features/assistant/assistant_controller_test.dart` (fakes for recorder, playback and picker; timing shortened).

**Tests:** the greeting is the first message; text send (user bubble, log call with truncation, reply after the delay); voice flow (record, stop, review, send gives an audio bubble and 'Voice Advisory'); permission denied; the photo flow and the analyzing-then-result keys; discard clears; logging failure is ignored; the language toggle; a reply arrives after close.

### Task 2: UI

**Files:**
- `lib/features/assistant/floating_assistant.dart`: launcher and panel.
- `widgets/chat_bubble.dart`, `widgets/assistant_input_bar.dart`, `widgets/waveform.dart`, `widgets/robot_hero.dart`.
- `AppShell`: include it and pass the location.
- The shell route builder passes `state.uri`.

**Tests (widget):**
- "auto-opens once after 1s" (enabled via an override);
- "tip mic opens the panel";
- "launcher opens, X closes, outside tap closes";
- "typing shows send; sending shows bubble and reply";
- "language toggle switches greeting and labels";
- "tab switch closes and resets language";
- "photo from gallery goes to review, send shows image bubble then analysis";
- "record → review → send shows voice bubble";
- "mic denied shows toast";
- "Urdu small screen fits".

Other test files keep auto-open off by default through a test-helper flag.

### Task 3: Emulator check

Open, send text, send a gallery photo, record a voice note (the emulator mic), and switch the language. Screenshots.
