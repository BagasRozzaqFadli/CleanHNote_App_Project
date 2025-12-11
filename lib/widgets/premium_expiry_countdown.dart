import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/premium_downgrade_service.dart';

/// Real-time Premium Expiry Countdown Widget
/// Shows days, hours, minutes, seconds remaining until premium expires
/// Auto-triggers downgrade when countdown reaches zero
class PremiumExpiryCountdown extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onExpired;

  const PremiumExpiryCountdown({super.key, required this.user, this.onExpired});

  @override
  State<PremiumExpiryCountdown> createState() => _PremiumExpiryCountdownState();
}

class _PremiumExpiryCountdownState extends State<PremiumExpiryCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemaining();
      }
    });
  }

  void _updateRemaining() {
    final expiry = widget.user.premiumExpiresAt;
    if (expiry == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }

    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.isNegative || difference == Duration.zero) {
      if (!_hasExpired) {
        _hasExpired = true;
        _handleExpiry();
      }
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = difference);
    }
  }

  Future<void> _handleExpiry() async {
    // Auto-downgrade
    await PremiumDowngradeService().checkAndApplyDowngrade(widget.user.uid);
    widget.onExpired?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Premium has expired. Downgraded to Free plan.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.premiumExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final isExpiringSoon = _remaining.inHours < 24;
    final expired = _remaining == Duration.zero;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: expired
              ? [Colors.red.shade700, Colors.red.shade900]
              : isExpiringSoon
              ? [Colors.orange.shade600, Colors.deepOrange.shade700]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (expired
                        ? Colors.red
                        : isExpiringSoon
                        ? Colors.orange
                        : Colors.purple)
                    .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expired
                    ? Icons.error
                    : isExpiringSoon
                    ? Icons.warning_amber_rounded
                    : Icons.timer,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                expired
                    ? 'Premium Expired'
                    : isExpiringSoon
                    ? 'Premium Expiring Soon!'
                    : 'Premium Expires In',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Countdown Display
          if (!expired)
            ScaleTransition(
              scale: isExpiringSoon
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeUnit(days, 'Days', Icons.calendar_today),
                  _buildDivider(),
                  _buildTimeUnit(hours, 'Hours', Icons.schedule),
                  _buildDivider(),
                  _buildTimeUnit(minutes, 'Min', Icons.timelapse),
                  _buildDivider(),
                  _buildTimeUnit(seconds, 'Sec', Icons.timer_outlined),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '00:00:00:00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Expiry Date
          Text(
            expired
                ? 'Expired on ${_formatDate(widget.user.premiumExpiresAt!)}'
                : 'Expires on ${_formatDate(widget.user.premiumExpiresAt!)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Text(
      ':',
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
