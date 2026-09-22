import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/services/security_service.dart';

/// State management for the QDS security and verification layer.
///
/// Binds directly to the real verification evidence from [SecurityService],
/// maintaining reactive state for active security status, recent audit events,
/// and currently selected message telemetry without creating fake data.
class SecurityProvider extends ChangeNotifier {
  SecurityProvider({SecurityService? service})
      : _service = service ?? SecurityService.instance {
    _initSubscriptions();
  }

  final SecurityService _service;

  SecurityTelemetry? _selectedTelemetry;
  String? _lastAlertedEventId;
  bool _alertDismissed = false;

  StreamSubscription<SecurityEventModel>? _eventSub;
  StreamSubscription<QdsSecurityStatus>? _statusSub;
  StreamSubscription<SecurityTelemetry>? _telemetrySub;

  /// Underlying security service.
  SecurityService get service => _service;

  /// Global security status derived from the latest backend verification.
  QdsSecurityStatus get currentStatus => _service.currentStatus;

  /// Latest verification telemetry received.
  SecurityTelemetry? get latestTelemetry => _service.latestTelemetry;

  /// Recent real security events audit log (latest first).
  List<SecurityEventModel> get recentEvents => _service.events;

  /// Currently selected telemetry for message-level inspection dialogs.
  SecurityTelemetry? get selectedTelemetry => _selectedTelemetry;

  /// The most recent threat, suspicious, or verification failure audit event, if any.
  SecurityEventModel? get latestThreatEvent {
    for (final event in recentEvents) {
      if (event.status == QdsSecurityStatus.threatDetected ||
          event.status == QdsSecurityStatus.suspicious ||
          event.status == QdsSecurityStatus.verificationFailed) {
        return event;
      }
    }
    return null;
  }

  /// Returns an active, unacknowledged threat event to present an alert exactly once.
  /// Returns null if the event was already dismissed or acknowledged.
  SecurityEventModel? get activeThreatAlert {
    final threat = latestThreatEvent;
    if (threat == null) return null;
    if (_alertDismissed && threat.id == _lastAlertedEventId) return null;
    return threat;
  }

  void _initSubscriptions() {
    _eventSub = _service.onSecurityEvent.listen((event) {
      if (event.status == QdsSecurityStatus.threatDetected ||
          event.status == QdsSecurityStatus.suspicious ||
          event.status == QdsSecurityStatus.verificationFailed) {
        _alertDismissed = false;
      }
      notifyListeners();
    });
    _statusSub = _service.onStatusChanged.listen((_) => notifyListeners());
    _telemetrySub = _service.onTelemetryReceived.listen((_) => notifyListeners());
  }

  /// Ingests message verification telemetry into the security layer.
  void consumeMessage(MessageModel message) {
    _service.processMessageSecurity(message);
  }

  /// Dismisses the active threat alert banner for the current event.
  void dismissThreatAlert() {
    final threat = latestThreatEvent;
    if (threat != null) {
      _lastAlertedEventId = threat.id;
    }
    _alertDismissed = true;
    notifyListeners();
  }

  /// Explicitly acknowledges an event by its ID.
  void acknowledgeEvent(String eventId) {
    _lastAlertedEventId = eventId;
    _alertDismissed = true;
    notifyListeners();
  }

  /// Sets the currently inspected telemetry for message details views.
  void selectTelemetry(SecurityTelemetry? telemetry) {
    _selectedTelemetry = telemetry;
    notifyListeners();
  }

  /// Resets state for testing.
  void clear() {
    _selectedTelemetry = null;
    _lastAlertedEventId = null;
    _alertDismissed = false;
    _service.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _telemetrySub?.cancel();
    super.dispose();
  }
}
