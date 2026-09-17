import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/user_model.dart';

/// Representation of a conversation thread between sender and receiver in QDS.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.peerName,
    required this.peerRole,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCount = 0,
    this.securityStatus = QdsSecurityStatus.trusted,
    this.isOnline,
  });

  final String id;
  final String peerName;
  final UserRole peerRole;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final QdsSecurityStatus securityStatus;
  final bool? isOnline;

  ConversationModel copyWith({
    String? id,
    String? peerName,
    UserRole? peerRole,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
    QdsSecurityStatus? securityStatus,
    bool? isOnline,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      peerName: peerName ?? this.peerName,
      peerRole: peerRole ?? this.peerRole,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      securityStatus: securityStatus ?? this.securityStatus,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'peerName': peerName,
    'peerRole': peerRole.code,
    'lastMessage': lastMessage,
    'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
    'unreadCount': unreadCount,
    'securityStatus': securityStatus.name,
    'isOnline': isOnline,
  };

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      peerName: json['peerName'] as String? ?? '',
      peerRole: UserRole.fromCode(json['peerRole'] as String?) ?? UserRole.receiver,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.tryParse(json['lastMessageTimestamp'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      securityStatus: QdsSecurityStatus.values.firstWhere(
        (e) => e.name == json['securityStatus'],
        orElse: () => QdsSecurityStatus.trusted,
      ),
      isOnline: json['isOnline'] as bool?,
    );
  }
}
