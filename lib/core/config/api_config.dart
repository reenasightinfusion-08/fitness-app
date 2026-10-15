/// Backend address. Defaults to the live server; point a debug build at a
/// local one with `--dart-define=API_BASE_URL=http://10.0.2.2:4000` (Android
/// emulator) or your computer's LAN IP on a physical phone.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fitness-backend-eight.vercel.app',
  );
}
