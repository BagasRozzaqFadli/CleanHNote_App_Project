import 'package:flutter/material.dart';
import 'dart:async';

/// Widget to display auto-deletion countdown for tasks
class CountdownBadge extends StatefulWidget {
  final Duration? timeUntilDeletion;
  final String countdownText;

  const CountdownBadge({
    super.key,
    required this.timeUntilDeletion,
    required this.countdownText,
  });

  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timeUntilDeletion == null || widget.countdownText.isEmpty) {
      return const SizedBox.shrink();
    }

    final days = widget.timeUntilDeletion!.inDays;
    Color bgColor;
    Color textColor;

    if (days <= 3) {
      bgColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
    } else if (days <= 7) {
      bgColor = Colors.orange[100]!;
      textColor = Colors.orange[900]!;
    } else if (days <= 14) {
      bgColor = Colors.yellow[100]!;
      textColor = Colors.yellow[900]!;
    } else {
      bgColor = Colors.blue[50]!;
      textColor = Colors.blue[900]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            widget.countdownText,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
