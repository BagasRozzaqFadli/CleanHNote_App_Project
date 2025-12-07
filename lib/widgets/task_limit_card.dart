import 'package:flutter/material.dart';

/// Simple task limit indicator card
class TaskLimitCard extends StatelessWidget {
  final int currentCount;
  final int? maxLimit; // null = unlimited (premium)
  final bool isPremium;

  const TaskLimitCard({
    super.key,
    required this.currentCount,
    this.maxLimit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _buildPremiumCard();
    } else {
      return _buildFreeCard();
    }
  }

  Widget _buildPremiumCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Premium - Unlimited Tasks',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
          ),
          Text(
            '$currentCount active',
            style: TextStyle(
              fontSize: 13,
              color: Colors.indigo[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCard() {
    final maxLimit = this.maxLimit ?? 5;
    final progress = currentCount / maxLimit;
    final isWarning = currentCount >= 3 && currentCount < maxLimit;
    final isLimitReached = currentCount >= maxLimit;

    Color borderColor;
    Color backgroundColor;
    Color textColor;

    if (isLimitReached) {
      borderColor = Colors.red[300]!;
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[800]!;
    } else if (isWarning) {
      borderColor = Colors.orange[300]!;
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
    } else {
      borderColor = Colors.blue[200]!;
      backgroundColor = Colors.blue[50]!;
      textColor = Colors.blue[800]!;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isLimitReached
                    ? Icons.info_outline
                    : isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.task_alt,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Task Limit: $currentCount / $maxLimit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.white.withOpacity(0.6),
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              minHeight: 6,
            ),
          ),
          if (isLimitReached) ...[
            const SizedBox(height: 8),
            Text(
              'Limit reached. Complete or delete tasks to add more.',
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.9)),
            ),
          ],
        ],
      ),
    );
  }
}
