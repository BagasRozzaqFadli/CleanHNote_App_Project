import 'package:flutter/material.dart';

/// Widget to display real-time countdown with seconds
class RealtimeCountdownWidget extends StatefulWidget {
  final DateTime targetTime;
  final TextStyle? style;

  const RealtimeCountdownWidget({
    super.key,
    required this.targetTime,
    this.style,
  });

  @override
  State<RealtimeCountdownWidget> createState() =>
      _RealtimeCountdownWidgetState();
}

class _RealtimeCountdownWidgetState extends State<RealtimeCountdownWidget> {
  late Stream<String> _countdownStream;

  @override
  void initState() {
    super.initState();
    _countdownStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => _formatCountdown(widget.targetTime),
    );
  }

  String _formatCountdown(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);

    if (diff.isNegative) return 'Expired';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      return 'Deletes in ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Deletes in ${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return 'Deletes in ${minutes}m ${seconds}s';
    } else {
      return 'Deletes in ${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _countdownStream,
      initialData: _formatCountdown(widget.targetTime),
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Calculating...', style: widget.style);
      },
    );
  }
}
