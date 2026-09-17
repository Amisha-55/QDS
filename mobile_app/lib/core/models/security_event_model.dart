import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_telemetry.dart';

/// Represents an immutable, verifiable security audit event generated from real
/// cryptographic verification outputs received from the QDS backend.
class SecurityEventModel {
  const SecurityEventModel({
    required this.id,
    required this.messageId,
    required this.timestamp,
    required this.status,
    required this.attackType,
    required this.summary,
    this.signerId,
    this.telemetry,
  });

  /// Unique event identifier.
  final String id;

  /// Associated message ID (deduplication and traceability key).
  final String messageId;

  /// Timestamp of event generation.
  final DateTime timestamp;

  /// Evidence-based security status.
  final QdsSecurityStatus status;

  /// Classified attack type (e.g. "LEGITIMATE", "REPLAY", "CHANNEL_ATTACK", "FORGERY_OR_IMPERSONATION", "UNKNOWN").
  final String attackType;

  /// Human-readable factual summary of the verification outcome.
  final String summary;

  /// Identified signer if available.
  final String? signerId;

  /// Full underlying telemetry from the research pipeline.
  final SecurityTelemetry? telemetry;

  /// Constructs a [SecurityEventModel] from an incoming or acknowledged [MessageModel].
  factory SecurityEventModel.fromMessage({
    required MessageModel message,
    required SecurityTelemetry telemetry,
    required QdsSecurityStatus status,
  }) {
    final eventId = 'evt_${message.id}_${DateTime.now().millisecondsSinceEpoch}';
    final attackType = telemetry.likelyAttackType ?? 'NONE';
    final summary = _generateSummary(telemetry, status);

    return SecurityEventModel(
      id: eventId,
      messageId: message.id,
      timestamp: message.timestamp,
      status: status,
      attackType: attackType,
      summary: summary,
      signerId: telemetry.signerId,
      telemetry: telemetry,
    );
  }

  static String _generateSummary(SecurityTelemetry telemetry, QdsSecurityStatus status) {
    if (telemetry.replayDetected == true) {
      return 'Cryptographic signature replay detected for packet.';
    }
    if (telemetry.likelyAttackType?.toUpperCase() == 'CHANNEL_ATTACK') {
      final acc = telemetry.verificationAccuracy != null
          ? ' (accuracy ${(telemetry.verificationAccuracy! * 100).toStringAsFixed(1)}%)'
          : '';
      return 'Quantum channel noise or manipulation detected$acc.';
    }
    if (telemetry.likelyAttackType?.toUpperCase() == 'FORGERY_OR_IMPERSONATION' ||
        telemetry.likelyAttackType?.toUpperCase() == 'FORGERY') {
      return 'Classical Ed25519 signature validation failed. Possible forgery or impersonation attempt.';
    }
    if (telemetry.classicalSignatureValid == false) {
      return 'Classical digital signature is invalid.';
    }
    if (telemetry.qdsValid == false) {
      return 'Quantum-inspired digital signature validation failed.';
    }
    if (status == QdsSecurityStatus.trusted) {
      final acc = telemetry.verificationAccuracy != null
          ? ' with ${(telemetry.verificationAccuracy! * 100).toStringAsFixed(1)}% quantum fidelity'
          : '';
      return 'Classical and quantum signatures verified successfully$acc.';
    }
    return 'Digital signature verification completed with status: ${status.label}.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'attackType': attackType,
        'summary': summary,
        if (signerId != null) 'signerId': signerId,
        if (telemetry != null) 'telemetry': telemetry!.toJson(),
      };

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      id: json['id'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: QdsSecurityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QdsSecurityStatus.monitoring,
      ),
      attackType: json['attackType'] as String? ?? 'NONE',
      summary: json['summary'] as String? ?? '',
      signerId: json['signerId'] as String?,
      telemetry: json['telemetry'] != null
          ? SecurityTelemetry.fromJson(json['telemetry'] as Map<String, dynamic>)
          : null,
    );
  }
}
