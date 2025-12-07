import 'package:flutter/material.dart';
import '../models/team_analytics.dart';
import '../services/team_analytics_service.dart';
import '../services/pdf_export_service.dart';

/// Member Performance Detail Screen
/// Shows individual member statistics and task history
class MemberPerformanceScreen extends StatefulWidget {
  final String teamId;
  final String memberId;

  const MemberPerformanceScreen({
    Key? key,
    required this.teamId,
    required this.memberId,
  }) : super(key: key);

  @override
  State<MemberPerformanceScreen> createState() =>
      _MemberPerformanceScreenState();
}

class _MemberPerformanceScreenState extends State<MemberPerformanceScreen> {
  final _analyticsService = TeamAnalyticsService();
  MemberPerformance? _member;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, completed, late, incomplete

  @override
  void initState() {
    super.initState();
    _analyticsService.initialize();
    _loadMemberPerformance();
  }

  Future<void> _loadMemberPerformance() async {
    final member = await _analyticsService.getMemberPerformance(
      widget.teamId,
      widget.memberId,
    );
    setState(() {
      _member = member;
      _isLoading = false;
    });
  }

  List<TaskHistory> get _filteredTasks {
    if (_member == null) return [];
    final tasks = _member!.recentTasks;

    switch (_selectedFilter) {
      case 'completed':
        return tasks.where((t) => t.status == 'completed').toList();
      case 'late':
        return tasks.where((t) => t.status == 'late').toList();
      case 'incomplete':
        return tasks.where((t) => t.status == 'incomplete').toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Member Performance'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              _exportToPDF();
            },
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _member == null
          ? _buildNoData()
          : _buildContent(),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Text(
        'Member not found',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMemberProfile(),
          const SizedBox(height: 20),
          _buildPerformanceStats(),
          const SizedBox(height: 20),
          _buildTaskHistory(),
        ],
      ),
    );
  }

  Widget _buildMemberProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _member!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _member!.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Member since ${_formatDate(_member!.joinedAt)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    final stats = _member!.stats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Performance Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Total Assigned',
            '${stats.assigned}',
            Icons.assignment,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '✅ Completed',
            '${stats.completed} (${stats.completionRate.toStringAsFixed(1)}%)',
            Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '⏰ On-Time',
            '${stats.completed - stats.late} (${stats.onTimeRate.toStringAsFixed(1)}%)',
            Icons.access_time,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '❌ Late',
            '${stats.late}',
            Icons.schedule,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '💀 Incomplete',
            '${stats.incomplete}',
            Icons.cancel,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '⏱️ Avg Time',
            '${(stats.avgCompletionHours / 24).toStringAsFixed(1)} days',
            Icons.speed,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[700]),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 15)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Task History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          if (_filteredTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No tasks found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                return _buildTaskItem(_filteredTasks[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _selectedFilter == 'all',
          onSelected: (selected) {
            setState(() => _selectedFilter = 'all');
          },
        ),
        FilterChip(
          label: const Text('Completed'),
          selected: _selectedFilter == 'completed',
          onSelected: (selected) {
            setState(() => _selectedFilter = 'completed');
          },
        ),
        FilterChip(
          label: const Text('Late'),
          selected: _selectedFilter == 'late',
          onSelected: (selected) {
            setState(() => _selectedFilter = 'late');
          },
        ),
        FilterChip(
          label: const Text('Incomplete'),
          selected: _selectedFilter == 'incomplete',
          onSelected: (selected) {
            setState(() => _selectedFilter = 'incomplete');
          },
        ),
      ],
    );
  }

  Widget _buildTaskItem(TaskHistory task) {
    final statusIcon = task.status == 'completed'
        ? Icons.check_circle
        : task.status == 'late'
        ? Icons.schedule
        : Icons.cancel;

    final statusColor = task.status == 'completed'
        ? Colors.green
        : task.status == 'late'
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 28),
            Text(
              'Assigned: ${_formatDate(task.assignedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Spacer(),
            if (task.completedAt != null)
              Text(
                'Done: ${_formatDate(task.completedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        if (task.completionTimeHours != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 28),
              Text(
                'Took ${(task.completionTimeHours! / 24).toStringAsFixed(1)} days',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _exportToPDF() async {
    if (_member == null) return;

    setState(() => _isLoading = true);

    try {
      // Get team analytics to get team name
      final analytics = await _analyticsService.getTeamAnalytics(widget.teamId);
      final teamName = analytics?.teamName ?? 'Team';

      // Generate PDF
      final pdf = await PdfExportService.generateMemberReport(
        _member!,
        teamName,
      );

      // Share PDF
      await PdfExportService.sharePdf(
        pdf,
        'Member_Performance_${_member!.name.replaceAll(' ', '_')}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
