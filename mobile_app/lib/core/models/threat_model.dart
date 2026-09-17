import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_telemetry.dart';

/// Representation of an actual threat detected from real verification telemetry.
/// Strictly based on evidence from the Python research core (e.g. replay, channel noise, forgery).
/// Does not fabricate numerical scores or arbitrary severity levels.
class ThreatModel {
  const ThreatModel({
    required this.id,
    required this.messageId,
    required this.attackType,
    required this.description,
    required this.timestamp,
    required this.status,
    this.telemetry,
  });

  final String id;
  final String messageId;
  final String attackType;
  final String description;
  final DateTime timestamp;
  final QdsSecurityStatus status;
  final SecurityTelemetry? telemetry;

  factory ThreatModel.fromTelemetry({
    required String messageId,
    required SecurityTelemetry telemetry,
    required QdsSecurityStatus status,
    DateTime? timestamp,
  }) {
    return ThreatModel(
      id: 'th_${messageId}_${DateTime.now().millisecondsSinceEpoch}',
      messageId: messageId,
      attackType: telemetry.likelyAttackType ?? 'UNKNOWN',
      description: telemetry.displayAttackType,
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      telemetry: telemetry,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'attackType': attackType,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        if (telemetry != null) 'telemetry': telemetry!.toJson(),
      };
}
