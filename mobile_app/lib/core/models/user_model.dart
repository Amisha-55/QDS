/// Demonstration roles for the QDS prototype.
enum UserRole {
  sender(
    code: 'X',
    label: 'Sender',
    description: 'Use this device as the message sender.',
  ),
  receiver(
    code: 'Y',
    label: 'Receiver',
    description: 'Use this device as the message receiver.',
  );

  const UserRole({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;

  static UserRole? fromCode(String? code) {
    if (code == 'X') return UserRole.sender;
    if (code == 'Y') return UserRole.receiver;
    return null;
  }
}

/// Local identity representation for the QDS prototype.
class UserModel {
  const UserModel({
    required this.name,
    required this.role,
  });

  final String name;
  final UserRole role;

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role.code,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      role: UserRole.fromCode(json['role'] as String?) ?? UserRole.sender,
    );
  }
}
