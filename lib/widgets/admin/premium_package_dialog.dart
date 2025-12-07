import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

/// Premium package selection dialog
class PremiumPackageDialog extends StatefulWidget {
  final UserModel user;

  const PremiumPackageDialog({super.key, required this.user});

  @override
  State<PremiumPackageDialog> createState() => _PremiumPackageDialogState();
}

class _PremiumPackageDialogState extends State<PremiumPackageDialog> {
  int? _selectedPackage;

  final List<Map<String, dynamic>> _packages = [
    {'months': 1, 'price': 'Rp 29.000', 'label': '1 Month Premium'},
    {'months': 3, 'price': 'Rp 79.000', 'label': '3 Months Premium'},
    {'months': 12, 'price': 'Rp 290.000', 'label': '1 Year Premium'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Packages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'for ${widget.user.username}',
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
              const SizedBox(height: 24),

              // Current Status
              if (widget.user.premiumExpiresAt != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current premium expires: ${_formatDate(widget.user.premiumExpiresAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.user.premiumExpiresAt != null)
                const SizedBox(height: 16),

              // Package Selection
              const Text(
                'Select Package:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ..._packages.asMap().entries.map((entry) {
                final index = entry.key;
                final package = entry.value;
                return _buildPackageCard(
                  index: index,
                  months: package['months'] as int,
                  price: package['price'] as String,
                  label: package['label'] as String,
                );
              }),

              const SizedBox(height: 24),

              // Preview
              if (_selectedPackage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New expiry date: ${_formatDate(_calculateNewExpiry(_packages[_selectedPackage!]['months'] as int))}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedPackage == null
                          ? null
                          : () => _confirmUpgrade(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required int index,
    required int months,
    required String price,
    required String label,
  }) {
    final isSelected = _selectedPackage == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.amber.shade800
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (months == 12)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DateTime _calculateNewExpiry(int months) {
    final now = DateTime.now();
    final currentExpiry = widget.user.premiumExpiresAt;

    // If user already has premium and it's not expired yet, extend from current expiry
    if (currentExpiry != null && currentExpiry.isAfter(now)) {
      return DateTime(
        currentExpiry.year,
        currentExpiry.month + months,
        currentExpiry.day,
      );
    }

    // Otherwise, start from now
    return DateTime(now.year, now.month + months, now.day);
  }

  Future<void> _confirmUpgrade(BuildContext context) async {
    if (_selectedPackage == null) return;

    try {
      final months = _packages[_selectedPackage!]['months'] as int;

      await DatabaseService().upgradeToPremium(widget.user.uid, months);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.user.username} upgraded to Premium for $months month(s)!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
