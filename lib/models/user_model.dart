import 'package:cloud_firestore/cloud_firestore.dart';

/// User model with role-based access and tenant identification
class UserModel {
  final String uid;
  final String email;
  final String username; // Display name, editable by user
  final String role; // 'free', 'premium', or 'admin'
  final String tenantId; // 6-character alphanumeric for admin search
  final List<String> joinedTeamIds; // IDs of teams user has joined
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.tenantId,
    this.joinedTeamIds = const [],
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] ?? '';
    return UserModel(
      uid: doc.id,
      email: email,
      username: data['username'] ?? _generateUsernameFromEmail(email),
      role: data['role'] ?? 'free',
      tenantId: data['tenantId'] ?? '',
      joinedTeamIds: List<String>.from(data['joinedTeamIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Generate username from email (part before @)
  static String _generateUsernameFromEmail(String email) {
    if (email.isEmpty) return 'User';
    final parts = email.split('@');
    return parts.isNotEmpty ? parts[0] : 'User';
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'tenantId': tenantId,
      'joinedTeamIds': joinedTeamIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Generate random 6-character tenant ID
  static String generateTenantId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    var seed = random;

    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      result += chars[seed % chars.length];
    }

    return result;
  }

  /// Check if user has premium access
  bool get isPremium => role == 'premium';

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is in any team
  bool get isInTeam => joinedTeamIds.isNotEmpty;

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? role,
    String? tenantId,
    List<String>? joinedTeamIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      joinedTeamIds: joinedTeamIds ?? this.joinedTeamIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
