import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:qds/core/constants/api_constants.dart';

/// Connection states for the QDS WebSocket client.
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed;
}

/// Function signature for creating a WebSocket connection (allows mocking in tests).
typedef WebSocketConnector = Future<WebSocket> Function(String url);

/// Encapsulated WebSocket client providing resilient JSON communication with QDS Gateway.
class WebSocketClient {
  WebSocketClient({
    WebSocketConnector? connector,
    this.maxReconnectAttempts = 5,
    bool? autoReconnect,
  })  : _connector = connector ?? _defaultConnector,
        autoReconnect = autoReconnect ?? (!Platform.environment.containsKey('FLUTTER_TEST'));

  final WebSocketConnector _connector;
  final int maxReconnectAttempts;
  final bool autoReconnect;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  String? _currentUrl;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast(sync: true);
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Current connection state.
  WebSocketConnectionState get state => _state;

  /// Stream of connection state updates.
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// Stream of validated JSON messages from the gateway.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Whether currently connected to the gateway.
  bool get isConnected => _state == WebSocketConnectionState.connected;

  /// Whether currently running inside an automated test suite.
  static bool get isTestEnvironment {
    try {
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  static Future<WebSocket> _defaultConnector(String url) async {
    return WebSocket.connect(url).timeout(const Duration(seconds: 5));
  }

  /// Connect to the gateway. Defaults to [ApiConstants.wsUrl].
  Future<void> connect({String? url}) async {
    _currentUrl = url ?? ApiConstants.wsUrl;
    _intentionalDisconnect = false;
    _reconnectTimer?.cancel();

    if (_state == WebSocketConnectionState.connected ||
        _state == WebSocketConnectionState.connecting) {
      return;
    }

    if (isTestEnvironment && _connector == _defaultConnector) {
      dev.log('Test environment detected with default connector; skipping real socket connection.', name: 'WebSocketClient');
      _updateState(WebSocketConnectionState.disconnected);
      return;
    }

    _updateState(WebSocketConnectionState.connecting);

    try {
      dev.log('Connecting to QDS Gateway at $_currentUrl', name: 'WebSocketClient');
      _socket = await _connector(_currentUrl!);
      _reconnectAttempts = 0;
      _updateState(WebSocketConnectionState.connected);

      _subscription = _socket!.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: true,
      );
    } catch (e) {
      dev.log('Connection failed: $e', name: 'WebSocketClient');
      _handleConnectionFailure();
    }
  }

  /// Send a JSON map over the active WebSocket.
  bool sendJson(Map<String, dynamic> data) {
    if (_socket == null || _state != WebSocketConnectionState.connected) {
      dev.log('Cannot send message: WebSocket is not connected.', name: 'WebSocketClient');
      return false;
    }

    try {
      final jsonString = jsonEncode(data);
      _socket!.add(jsonString);
      return true;
    } catch (e) {
      dev.log('Failed to send WebSocket message: $e', name: 'WebSocketClient');
      return false;
    }
  }

  /// Disconnect cleanly from the gateway.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    await _subscription?.cancel();
    _subscription = null;

    if (_socket != null) {
      try {
        await _socket!.close(WebSocketStatus.normalClosure);
      } catch (e) {
        dev.log('Error closing socket: $e', name: 'WebSocketClient');
      }
      _socket = null;
    }

    _updateState(WebSocketConnectionState.disconnected);
  }

  void _handleData(dynamic event) {
    try {
      final String rawString = event is String ? event : utf8.decode(event as List<int>);
      final dynamic decoded = jsonDecode(rawString);

      if (decoded is Map<String, dynamic>) {
        _messageController.add(decoded);
      } else {
        dev.log('Ignored non-object WebSocket frame: $decoded', name: 'WebSocketClient');
      }
    } catch (e) {
      dev.log('Failed to parse incoming WebSocket JSON: $e', name: 'WebSocketClient');
    }
  }

  void _handleError(dynamic error) {
    dev.log('WebSocket stream error: $error', name: 'WebSocketClient');
    _handleConnectionFailure();
  }

  void _handleDone() {
    dev.log('WebSocket closed by remote peer.', name: 'WebSocketClient');
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    } else {
      _updateState(WebSocketConnectionState.disconnected);
    }
  }

  void _handleConnectionFailure() {
    if (_intentionalDisconnect) {
      _updateState(WebSocketConnectionState.disconnected);
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!autoReconnect || _intentionalDisconnect) {
      _updateState(WebSocketConnectionState.disconnected);
      return;
    }

    if (_reconnectAttempts >= maxReconnectAttempts) {
      dev.log('Max reconnect attempts ($maxReconnectAttempts) reached. Giving up.', name: 'WebSocketClient');
      _updateState(WebSocketConnectionState.failed);
      return;
    }

    _reconnectAttempts++;
    _updateState(WebSocketConnectionState.reconnecting);

    // Exponential backoff: 1s, 2s, 4s, 8s, max 10s
    final delaySeconds = (1 << (_reconnectAttempts - 1)).clamp(1, 10);
    dev.log(
      'Scheduling reconnect attempt $_reconnectAttempts/$maxReconnectAttempts in ${delaySeconds}s...',
      name: 'WebSocketClient',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_intentionalDisconnect && _currentUrl != null) {
        connect(url: _currentUrl);
      }
    });
  }

  void _updateState(WebSocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  /// Dispose client and release stream resources.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
  }
}
