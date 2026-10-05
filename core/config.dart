/// Backend base URL (the FastAPI backend, local or on Vercel). Override per build, for example:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000/api/v1   (phone, same Wi-Fi)
///   flutter build apk --release --dart-define=API_URL=https://peanutiq-api.vercel.app/api/v1
/// The default reaches the backend on the host machine from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

/// Demo mode runs the app on built-in sample data with no backend:
///   flutter build apk --release --dart-define=DEMO_MODE=true
/// Sign in as demo@peanutiq.app with the password peanut123, or create a new account.
const bool demoMode = bool.fromEnvironment('DEMO_MODE');
