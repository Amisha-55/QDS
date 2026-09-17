/// Central API and Network Gateway configuration.
abstract final class ApiConstants {
  /// Default gateway host.
  /// - Desktop (Windows/macOS/Linux): '127.0.0.1'
  /// - Android Emulator: '10.0.2.2'
  /// - Physical Android device: Set to computer's LAN IP (e.g., '<LAPTOP_IP>')
  ///   via `--dart-define=QDS_GATEWAY_HOST=<LAPTOP_IP>` or runtime [customHost].
  static const String defaultHost = String.fromEnvironment(
    'QDS_GATEWAY_HOST',
    defaultValue: '127.0.0.1',
  );

  /// Default gateway port (default: 8000).
  static const int defaultPort = int.fromEnvironment(
    'QDS_GATEWAY_PORT',
    defaultValue: 8000,
  );

  /// Optional runtime overrides.
  static String? customHost;
  static int? customPort;

  /// Active gateway host.
  static String get host => customHost ?? defaultHost;

  /// Active gateway port.
  static int get port => customPort ?? defaultPort;

  /// Full WebSocket gateway endpoint.
  static String get wsUrl => 'ws://$host:$port/ws';

  /// Full HTTP REST gateway endpoint.
  static String get httpBaseUrl => 'http://$host:$port';
}
