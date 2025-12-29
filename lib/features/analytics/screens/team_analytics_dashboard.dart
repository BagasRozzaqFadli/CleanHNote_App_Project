import 'package:flutter/material.dart';
import '../models/team_analytics.dart';
import '../services/team_analytics_service.dart';
import '../services/realtime_analytics_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/analytics_charts.dart';
import 'member_performance_screen.dart';

/// Team Analytics Dashboard with Realtime Updates, Charts, and PDF Export
class TeamAnalyticsDashboard extends StatefulWidget {
  final String teamId;

  const TeamAnalyticsDashboard({Key? key, required this.teamId})
    : super(key: key);

  @override
  State<TeamAnalyticsDashboard> createState() => _TeamAnalyticsDashboardState();
}

class _TeamAnalyticsDashboardState extends State<TeamAnalyticsDashboard> {
  final _analyticsService = TeamAnalyticsService();
  final _realtimeService = RealtimeAnalyticsService();

  TeamAnalytics? _analytics;
  bool _isLoading = true;
  String? _errorMessage;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _analyticsService.initialize();
    _loadAnalytics();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    // Subscribe to realtime analytics updates
    _realtimeService
        .subscribeToTeamAnalytics(widget.teamId)
        .listen(
          (analytics) {
            if (analytics != null && mounted) {
              setState(() {
                _analytics = analytics;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            print('Realtime error: $error');
          },
        );

    // Listen to connection status
    _realtimeService.connectionStatus.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await _analyticsService.getTeamAnalytics(widget.teamId);

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;

          if (analytics == null) {
            _errorMessage = 'Could not load analytics data. Please try again.';
          }
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_analytics == null) return;

    setState(() => _isLoading = true);

    try {
      final pdf = await PdfExportService.generateTeamReport(_analytics!);
      await PdfExportService.sharePdf(pdf, 'Team_Analytics_${widget.teamId}');

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

  @override
  void dispose() {
    _realtimeService.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _connectionStatus.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _connectionStatus.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _connectionStatus.icon,
                      size: 16,
                      color: _connectionStatus.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connectionStatus.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: _connectionStatus.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Export PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAnalytics();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : _analytics == null
          ? _buildNoData()
          : _buildDashboard(),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Analytics Data Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start assigning tasks to see analytics',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 24),

            // Task Distribution Chart
            _buildChartSection(
              'Task Distribution',
              AnalyticsCharts.buildTaskDistributionChart(_analytics!),
              [
                LegendItem(label: 'Completed', color: Colors.green),
                LegendItem(label: 'Late', color: Colors.orange),
                LegendItem(label: 'Incomplete', color: Colors.red),
              ],
              height: 250,
            ),
            const SizedBox(height: 24),

            // Member Comparison Chart
            if (_analytics!.members.isNotEmpty) ...[
              _buildChartSection(
                'Member Comparison',
                AnalyticsCharts.buildMemberComparisonChart(_analytics!),
                [],
                height: 250,
              ),
              const SizedBox(height: 24),
            ],

            // Monthly Trends Chart
            if (_analytics!.monthlyTrends.isNotEmpty) ...[
              _buildChartSection(
                'Monthly Trends',
                AnalyticsCharts.buildMonthlyTrendChart(_analytics!),
                [
                  LegendItem(label: 'Completed', color: Colors.green),
                  LegendItem(label: 'Assigned', color: Colors.blue),
                ],
                height: 250,
              ),
              const SizedBox(height: 24),
            ],

            // Member Leaderboard
            _buildMemberLeaderboard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    Widget chart,
    List<LegendItem> legendItems, {
    double height = 200,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: chart),
          if (legendItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(child: AnalyticsCharts.buildChartLegend(legendItems)),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    // Check if we have any completed tasks for meaningful metrics
    final hasCompletedTasks = _analytics!.totalTasksCompleted > 0;
    final hasCompletionTime = _analytics!.averageCompletionTimeHours > 0;

    return Column(
      children: [
        // Row 1: Completion Rate & On-Time Rate
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Completion Rate',
                hasCompletedTasks
                    ? '${_analytics!.completionRate.toStringAsFixed(1)}%'
                    : 'N/A',
                Icons.check_circle_outline,
                hasCompletedTasks ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'On-Time Rate',
                hasCompletedTasks
                    ? '${_analytics!.onTimeRate.toStringAsFixed(1)}%'
                    : 'N/A',
                Icons.access_time,
                hasCompletedTasks ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Avg Completion & Total Tasks
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Completion',
                hasCompletedTasks && hasCompletionTime
                    ? '${(_analytics!.averageCompletionTimeHours / 24).toStringAsFixed(1)}d'
                    : 'N/A',
                Icons.speed,
                hasCompletedTasks && hasCompletionTime
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                '${_analytics!.totalTasksAssigned}',
                Icons.assignment,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberLeaderboard() {
    final sortedMembers = _analytics!.members.values.toList()
      ..sort((a, b) => b.stats.completed.compareTo(a.stats.completed));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Top Performers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sortedMembers.isEmpty)
            Center(
              child: Text(
                'No members yet',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedMembers.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final member = sortedMembers[index];
                return _buildMemberItem(member, index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(MemberPerformance member, int rank) {
    final emoji = rank == 1
        ? '👑'
        : rank == 2
        ? '⭐'
        : rank == 3
        ? '✨'
        : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberPerformanceScreen(
              teamId: widget.teamId,
              memberId: member.memberId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? Colors.deepPurple.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emoji.isNotEmpty ? emoji : '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.deepPurple : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    member.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${member.stats.completed} tasks',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${member.stats.completionRate.toStringAsFixed(0)}% rate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
