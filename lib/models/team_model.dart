import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Team model for premium users
class TeamModel {
  final String id;
  final String ownerId;
  final String name;
  final String inviteCode; // Unique code for joining
  final List<String> memberIds; // UIDs of team members
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Generate random 8-character invite code
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Check if user is the owner
  bool isOwner(String uid) => ownerId == uid;

  /// Check if user is a member
  bool isMember(String uid) => memberIds.contains(uid);

  /// Get total member count (including owner)
  int get totalMembers => memberIds.length;

  /// Create a copy with updated fields
  TeamModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? inviteCode,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
