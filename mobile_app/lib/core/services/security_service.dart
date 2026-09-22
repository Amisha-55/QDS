import 'dart:async';
import 'dart:developer' as dev;

import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/services/messaging_service.dart';

/// Centralized service boundary for security data and verification interpretation.
///
/// Converts raw backend telemetry attached to messages into typed [SecurityTelemetry],
/// derives evidence-based [QdsSecurityStatus], generates traceable [SecurityEventModel] audits,
/// and prevents duplicate events for the same message.
class SecurityService {
  SecurityService({MessagingService? messagingService})
      : _messagingService = messagingService ?? MessagingService.instance {
    _initSubscriptions();
  }

  static final SecurityService instance = SecurityService();

  final MessagingService _messagingService;

  final List<SecurityEventModel> _events = [];
  final Map<String, SecurityTelemetry> _telemetryByMessageId = {};
  final Set<String> _processedMessageIds = {};

  SecurityTelemetry? _latestTelemetry;
  QdsSecurityStatus _currentStatus = QdsSecurityStatus.monitoring;

  final StreamController<SecurityEventModel> _securityEventController =
      StreamController<SecurityEventModel>.broadcast();
  final StreamController<QdsSecurityStatus> _statusController =
      StreamController<QdsSecurityStatus>.broadcast();
  final StreamController<SecurityTelemetry> _telemetryController =
      StreamController<SecurityTelemetry>.broadcast();

  StreamSubscription<MessageModel>? _receivedSubscription;
  StreamSubscription<MessageModel>? _updatedSubscription;

  /// Stream of verifiable security events generated from real message outputs.
  Stream<SecurityEventModel> get onSecurityEvent => _securityEventController.stream;

  /// Stream of real-time security status changes.
  Stream<QdsSecurityStatus> get onStatusChanged => _statusController.stream;

  /// Stream of incoming security telemetry updates.
  Stream<SecurityTelemetry> get onTelemetryReceived => _telemetryController.stream;

  /// Unmodifiable list of all recorded security events.
  List<SecurityEventModel> get events => List.unmodifiable(_events);

  /// Latest security telemetry processed by the application.
  SecurityTelemetry? get latestTelemetry => _latestTelemetry;

  /// Current global security status derived from the latest verification evidence.
  QdsSecurityStatus get currentStatus => _currentStatus;

  void _initSubscriptions() {
    _receivedSubscription = _messagingService.onMessageReceived.listen(processMessageSecurity);
    _updatedSubscription = _messagingService.onMessageUpdated.listen(processMessageSecurity);
  }

  /// Central evidence-based mapping from [SecurityTelemetry] to [QdsSecurityStatus].
  ///
  /// This is the SINGLE SOURCE OF TRUTH for security interpretation.
  static QdsSecurityStatus mapTelemetryToSecurityStatus(SecurityTelemetry? telemetry) {
    if (telemetry == null || telemetry.isEmpty) {
      return QdsSecurityStatus.monitoring;
    }

    final likelyAttack = telemetry.likelyAttackType?.toUpperCase() ?? '';
    final finalDecision = telemetry.finalDecision?.toUpperCase() ?? '';
    final qdsDecision = telemetry.qdsDecision?.toUpperCase() ?? '';

    // 1. Replay attack check: explicit flag or classified as REPLAY
    if (telemetry.replayDetected == true ||
        likelyAttack.contains('REPLAY') ||
        finalDecision.contains('REPLAY')) {
      return QdsSecurityStatus.threatDetected;
    }

    // 2. Forgery or Impersonation check
    if (likelyAttack == 'FORGERY_OR_IMPERSONATION' ||
        likelyAttack == 'FORGERY' ||
        likelyAttack == 'IMPERSONATION') {
      return QdsSecurityStatus.threatDetected;
    }

    // 3. Channel manipulation check
    if (likelyAttack == 'CHANNEL_ATTACK') {
      return QdsSecurityStatus.suspicious;
    }

    // 4. Classical signature validation check
    if (telemetry.classicalSignatureValid == false) {
      return QdsSecurityStatus.suspicious;
    }

    // 5. Quantum-inspired digital signature check
    if (telemetry.qdsValid == false || qdsDecision == 'INVALID' || qdsDecision == 'REJECT') {
      return QdsSecurityStatus.verificationFailed;
    }

    // 6. Final decision check for suspicious/invalid results
    if (finalDecision.contains('INVALID') || finalDecision.contains('SUSPICIOUS')) {
      return QdsSecurityStatus.suspicious;
    }

    // 7. Legitimate & Verified check:
    // Requires classical signature valid, QDS valid, no replay, and accepted final decision
    final isFinalTrusted = finalDecision == 'TRUSTED' ||
        finalDecision == 'ACCEPT' ||
        finalDecision == 'VALID';

    final isAttackNone = likelyAttack.isEmpty ||
        likelyAttack == 'NONE' ||
        likelyAttack == 'LEGITIMATE';

    if (telemetry.classicalSignatureValid == true &&
        telemetry.qdsValid == true &&
        telemetry.replayDetected != true &&
        isFinalTrusted &&
        isAttackNone) {
      return QdsSecurityStatus.trusted;
    }

    // 8. Unknown/unrecognized telemetry combinations: conservative warning
    return QdsSecurityStatus.warning;
  }

  /// Static helper to derive [QdsSecurityStatus] directly from a raw map.
  static QdsSecurityStatus deriveSecurityStatus(Map<String, dynamic>? data) {
    final telemetry = SecurityTelemetry.fromJson(data);
    return mapTelemetryToSecurityStatus(telemetry);
  }

  /// Ingest a [MessageModel] and extract/audit its verification telemetry.
  /// Deduplicates events so that an outgoing message ACK and subsequent references
  /// do not create duplicate audit events.
  SecurityEventModel? processMessageSecurity(MessageModel message) {
    final rawData = message.securityData;
    if (rawData == null || rawData.isEmpty) {
      return null;
    }

    final telemetry = SecurityTelemetry.fromJson(rawData);
    final status = mapTelemetryToSecurityStatus(telemetry);

    if (message.id.isNotEmpty) {
      _telemetryByMessageId[message.id] = telemetry;
    }

    _latestTelemetry = telemetry;
    _currentStatus = status;
    _statusController.add(status);
    _telemetryController.add(telemetry);

    // Prevent duplicate event creation for the same message
    if (message.id.isNotEmpty && _processedMessageIds.contains(message.id)) {
      dev.log('Skipped duplicate event for message_id=${message.id}', name: 'SecurityService');
      return null;
    }

    if (message.id.isNotEmpty) {
      _processedMessageIds.add(message.id);
    }

    final event = SecurityEventModel.fromMessage(
      message: message,
      telemetry: telemetry,
      status: status,
    );

    _events.insert(0, event); // Latest first
    _securityEventController.add(event);

    return event;
  }

  /// Retrieve the parsed telemetry for a specific message by its ID.
  SecurityTelemetry? getTelemetryForMessage(String messageId) {
    return _telemetryByMessageId[messageId];
  }

  /// Retrieve the audit event associated with a specific message.
  SecurityEventModel? getEventForMessage(String messageId) {
    try {
      return _events.firstWhere((e) => e.messageId == messageId);
    } catch (_) {
      return null;
    }
  }

  /// Reset internal state for test cleanups.
  void clear() {
    _events.clear();
    _telemetryByMessageId.clear();
    _processedMessageIds.clear();
    _latestTelemetry = null;
    _currentStatus = QdsSecurityStatus.monitoring;
  }

  /// Dispose controllers and stream listeners.
  Future<void> dispose() async {
    await _receivedSubscription?.cancel();
    await _updatedSubscription?.cancel();
    await _securityEventController.close();
    await _statusController.close();
    await _telemetryController.close();
  }
}
