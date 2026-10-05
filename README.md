# PeanutIQ Mobile (Farmer app)

Flutter Android app for PeanutIQ farmers. It talks to the PeanutIQ FastAPI backend (a separate repo).

Screens: Create Account and Sign In (email + password), then five tabs: Home (dashboard), Seed, Disease, Knowledge, and More (History, Advisories, Profile, language, logout).

## Requirements
- Flutter 3.47+ (`flutter --version`)
- Android Studio (for its emulator) or an Android phone with USB debugging
- VS Code with the **Flutter** extension (recommended editor)

## Run
1. Start the backend (PeanutIQ repo, see `backend/README.md`) with
   `uvicorn app.main:app --host 0.0.0.0 --port 8000`, or use the deployed Vercel URL.
   Find your computer's network address with `ipconfig getifaddr en0` (Mac).
2. Start an emulator: in VS Code, open the command palette, run "Flutter: Launch Emulator".
3. Run the app:

   ```bash
   flutter pub get
   flutter run                      # emulator: reaches the Mac at 10.0.2.2
   flutter run --dart-define=API_URL=http://<backend-machine-IP>:8000/api/v1   # real phone, same Wi-Fi
   ```

   In VS Code you can also press F5.

### APK for a phone
- Against a backend on your network (plain `http://`): build a **debug** APK. Release builds
  refuse unencrypted `http://` traffic.

  ```bash
  flutter build apk --debug --dart-define=API_URL=http://<backend-machine-IP>:8000/api/v1
  ```
- Against the backend deployed on Vercel (HTTPS): a release APK.

  ```bash
  flutter build apk --release --dart-define=API_URL=http://10.0.2.2:8000/api/v1
  ```
- With no backend at all: `flutter build apk --release --dart-define=DEMO_MODE=true`
  (sign in as demo@peanutiq.app / peanut123).

## Test
```bash
flutter test
flutter analyze
```

## Translations
Strings live in `assets/translations/{en,ur}.json` (i18next format, copied from the website).
To add keys: write a `{"en": {...}, "ur": {...}}` file under `tool/translations/`, then run:

```bash
python3 tool/merge_translations.py tool/translations/<file>.json
```

## Docs
- Design spec: `docs/superpowers/specs/`
- Implementation plans: `docs/superpowers/plans/`
