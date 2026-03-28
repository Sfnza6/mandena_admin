class UserModel {
  final int id;
  final String username;
  final String phone;
  final String avatarUrl;
  final String? createdAt;
  final bool isBanned;
  final String bannedReason;

  UserModel({
    required this.id,
    required this.username,
    required this.phone,
    required this.avatarUrl,
    this.createdAt,
    required this.isBanned,
    required this.bannedReason,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    // دعم مفاتيح متعددة
    final rawBan = j['is_banned'] ?? j['banned'] ?? j['blocked'] ?? 0;
    final banStr = (rawBan is bool)
        ? (rawBan ? '1' : '0')
        : rawBan.toString().toLowerCase().trim();
    final banned = (banStr == '1' || banStr == 'true');

    return UserModel(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      username: (j['username'] ?? j['name'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      avatarUrl: (j['avatar_url'] ?? j['avatar'] ?? '').toString(),
      createdAt: j['created_at']?.toString(),
      isBanned: banned,
      bannedReason: (j['banned_reason'] ?? j['ban_reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'phone': phone,
    'avatar_url': avatarUrl,
    'created_at': createdAt,
    'is_banned': isBanned ? 1 : 0,
    'banned_reason': bannedReason,
  };

  UserModel copyWith({
    int? id,
    String? username,
    String? phone,
    String? avatarUrl,
    String? createdAt,
    bool? isBanned,
    String? bannedReason,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isBanned: isBanned ?? this.isBanned,
      bannedReason: bannedReason ?? this.bannedReason,
    );
  }
}
