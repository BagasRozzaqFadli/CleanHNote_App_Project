import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/team_analytics.dart';

/// Collection of interactive chart widgets for analytics
class AnalyticsCharts {
  /// Task Distribution Pie Chart (Completed/Late/Incomplete)
  static Widget buildTaskDistributionChart(TeamAnalytics analytics) {
    final completed = analytics.totalTasksCompleted - analytics.totalTasksLate;
    final late = analytics.totalTasksLate;
    final incomplete = analytics.totalTasksIncomplete;
    final total = completed + late + incomplete;

    if (total == 0) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: completed.toDouble(),
            title: '${((completed / total) * 100).toStringAsFixed(0)}%',
            color: Colors.green,
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (late > 0)
            PieChartSectionData(
              value: late.toDouble(),
              title: '${((late / total) * 100).toStringAsFixed(0)}%',
              color: Colors.orange,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (incomplete > 0)
            PieChartSectionData(
              value: incomplete.toDouble(),
              title: '${((incomplete / total) * 100).toStringAsFixed(0)}%',
              color: Colors.red,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }

  /// Member Comparison Bar Chart
  static Widget buildMemberComparisonChart(TeamAnalytics analytics) {
    final members = analytics.members.values.toList()
      ..sort((a, b) => b.stats.completed.compareTo(a.stats.completed));

    final topMembers = members.take(5).toList();

    if (topMembers.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topMembers.first.stats.completed.toDouble() * 1.2,
        barGroups: topMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: member.stats.completed.toDouble(),
                color: _getBarColor(index),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: topMembers.first.stats.completed.toDouble() * 1.2,
                  color: Colors.grey.shade200,
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= topMembers.length) return const Text('');
                final member = topMembers[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    member.name.split('@').first,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final member = topMembers[group.x.toInt()];
              return BarTooltipItem(
                '${member.name}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${member.stats.completed} tasks completed',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Monthly Trend Line Chart
  static Widget buildMonthlyTrendChart(TeamAnalytics analytics) {
    if (analytics.monthlyTrends.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final trends = analytics.monthlyTrends.toList()
      ..sort((a, b) => a.monthNumber.compareTo(b.monthNumber));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= trends.length) return const Text('');
                final trend = trends[value.toInt()];
                final monthNames = [
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
                return Text(
                  monthNames[trend.monthNumber - 1],
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Completed tasks line
          LineChartBarData(
            spots: trends.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.tasksCompleted.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          // Assigned tasks line
          LineChartBarData(
            spots: trends.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.tasksAssigned.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final trend = trends[spot.x.toInt()];
                final monthNames = [
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
                return LineTooltipItem(
                  '${monthNames[trend.monthNumber - 1]} ${trend.year}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: spot.barIndex == 0
                          ? 'Completed: ${spot.y.toInt()}'
                          : 'Assigned: ${spot.y.toInt()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Chart Legend
  static Widget buildChartLegend(List<LegendItem> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        );
      }).toList(),
    );
  }

  static Color _getBarColor(int index) {
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}

class LegendItem {
  final String label;
  final Color color;

  LegendItem({required this.label, required this.color});
}
