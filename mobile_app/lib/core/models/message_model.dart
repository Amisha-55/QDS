import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/user_model.dart';

/// Message transport and delivery status.
enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed;
}

/// Representation of a message in the QDS messaging system.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.status = MessageDeliveryStatus.sent,
    this.securityStatus,
    this.securityData,
  });

  final String id;
  final String conversationId;
  final UserRole senderRole;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageDeliveryStatus status;
  final QdsSecurityStatus? securityStatus;

  /// Raw security telemetry returned directly by the Python QDS Gateway.
  final Map<String, dynamic>? securityData;

  String? get finalDecision => securityData?['final_decision'] as String?;
  String? get likelyAttackType => securityData?['likely_attack_type'] as String?;
  bool? get classicalSignatureValid => securityData?['classical_signature_valid'] as bool?;
  bool? get qdsValid => securityData?['qds_valid'] as bool?;
  bool? get replayDetected => securityData?['replay_detected'] as bool?;
  double? get verificationAccuracy => (securityData?['verification_accuracy'] as num?)?.toDouble();
  double? get errorRate => (securityData?['error_rate'] as num?)?.toDouble();
  int? get quantumBitCount => securityData?['quantum_bit_count'] as int?;
  int? get totalShots => securityData?['total_shots'] as int?;
  int? get correctShots => securityData?['correct_shots'] as int?;
  double? get threshold => (securityData?['threshold'] as num?)?.toDouble();
  String? get qdsDecision => securityData?['qds_decision'] as String?;
  String? get signerId => securityData?['signer_id'] as String?;

  MessageModel copyWith({
    String? id,
    String? conversationId,
    UserRole? senderRole,
    String? senderName,
    String? content,
    DateTime? timestamp,
    MessageDeliveryStatus? status,
    QdsSecurityStatus? securityStatus,
    Map<String, dynamic>? securityData,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      securityStatus: securityStatus ?? this.securityStatus,
      securityData: securityData ?? this.securityData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderRole': senderRole.code,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'securityStatus': securityStatus?.name,
    if (securityData != null) 'securityData': securityData,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderRole: UserRole.fromCode(json['senderRole'] as String?) ?? UserRole.sender,
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageDeliveryStatus.sent,
      ),
      securityStatus: json['securityStatus'] != null
          ? QdsSecurityStatus.values.firstWhere(
              (e) => e.name == json['securityStatus'],
              orElse: () => QdsSecurityStatus.trusted,
            )
          : null,
      securityData: json['securityData'] as Map<String, dynamic>?,
    );
  }
}
