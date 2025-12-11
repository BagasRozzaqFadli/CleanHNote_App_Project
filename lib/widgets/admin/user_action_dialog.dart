import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import 'premium_package_dialog.dart';

/// Dialog for admin actions on a selected user
class UserActionDialog extends StatelessWidget {
  final UserModel user;

  const UserActionDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isPremium = user.isPremium;
    final isBanned = user.isBanned;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isBanned
                        ? Colors.red
                        : (isPremium ? Colors.amber : Colors.blue),
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // User Details
              _buildInfoRow('Tenant ID', user.tenantId),
              _buildInfoRow('Role', user.role.toUpperCase()),
              _buildInfoRow(
                'First Login',
                _formatDate(user.firstLoginAt ?? user.createdAt),
              ),
              if (isPremium && user.premiumExpiresAt != null)
                _buildInfoRow(
                  'Premium Expires',
                  _formatDate(user.premiumExpiresAt!),
                  isHighlight: true,
                ),
              _buildInfoRow(
                'Status',
                isBanned ? 'BANNED' : 'Active',
                isHighlight: isBanned,
              ),

              const Divider(height: 32),

              // Action Buttons
              const Text(
                'Admin Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Ban/Unban Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      context,
                      title: isBanned ? 'Unban User?' : 'Ban User?',
                      message: isBanned
                          ? 'This will allow ${user.username} to access the app again.'
                          : 'This will prevent ${user.username} from accessing the app.',
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        if (isBanned) {
                          await DatabaseService().unbanUser(user.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${user.username} has been unbanned',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          await DatabaseService().banUser(user.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${user.username} has been banned',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: Icon(isBanned ? Icons.check_circle : Icons.block),
                  label: Text(isBanned ? 'Unban User' : 'Ban User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBanned ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Upgrade to Premium Button
              if (!isPremium || user.premiumExpiresAt != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await showDialog(
                        context: context,
                        builder: (context) => PremiumPackageDialog(user: user),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: Text(
                      isPremium ? 'Extend Premium' : 'Upgrade to Premium',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 2-Minute Test Premium Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      context,
                      title: '2-Minute Test Premium?',
                      message:
                          'Grant ${user.username} premium access for 2 minutes?\n\nThis is for testing the countdown and auto-downgrade features.',
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        final expiryTime = DateTime.now().add(
                          const Duration(minutes: 2),
                        );

                        // Directly update Firestore with custom expiry time
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({
                              'role': 'premium',
                              'premiumExpiresAt': Timestamp.fromDate(
                                expiryTime,
                              ),
                            });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ ${user.username} granted 2-min test premium\nExpires at: ${expiryTime.hour}:${expiryTime.minute.toString().padLeft(2, '0')}',
                              ),
                              backgroundColor: Colors.purple,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text('2-Min Test Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
