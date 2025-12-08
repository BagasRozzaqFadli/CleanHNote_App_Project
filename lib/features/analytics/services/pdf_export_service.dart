import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/team_analytics.dart';

/// Service for generating and exporting PDF reports
class PdfExportService {
  /// Generate Team Analytics Report PDF
  static Future<pw.Document> generateTeamReport(TeamAnalytics analytics) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Team Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      analytics.teamName,
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${_formatDate(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Team ID: ${analytics.teamId}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Overview Statistics
          pw.Text(
            'Overview Statistics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          _buildStatsGrid(analytics),

          pw.SizedBox(height: 24),

          // Team Performance Metrics
          pw.Text(
            'Performance Metrics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          _buildPerformanceTable(analytics),

          pw.SizedBox(height: 24),

          // Member Leaderboard
          pw.Text(
            'Member Leaderboard',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          _buildMemberLeaderboard(analytics),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return pdf;
  }

  /// Generate Member Performance Report PDF
  static Future<pw.Document> generateMemberReport(
    MemberPerformance member,
    String teamName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Member Performance Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      member.name,
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      teamName,
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${_formatDate(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      member.email,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Performance Summary
          pw.Text(
            'Performance Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          _buildMemberStatsGrid(member),

          pw.SizedBox(height: 24),

          // Task History
          pw.Text(
            'Task History',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          _buildTaskHistoryTable(member),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return pdf;
  }

  /// Save PDF to file and return path
  static Future<File> savePdf(pw.Document pdf, String filename) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Share PDF
  static Future<void> sharePdf(pw.Document pdf, String filename) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: '$filename.pdf');
  }

  /// Print PDF
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Helper Methods

  static pw.Widget _buildStatsGrid(TeamAnalytics analytics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Row 1: Total, Completed, Completion Rate, On-Time Rate
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Tasks', '${analytics.totalTasksAssigned}'),
              _buildStatItem('Completed', '${analytics.totalTasksCompleted}'),
              _buildStatItem(
                'Completion Rate',
                '${analytics.completionRate.toStringAsFixed(1)}%',
              ),
              _buildStatItem(
                'On-Time Rate',
                '${analytics.onTimeRate.toStringAsFixed(1)}%',
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          // Row 2: Late, Incomplete, Avg Time, Active Members
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Late', '${analytics.totalTasksLate}'),
              _buildStatItem('Incomplete', '${analytics.totalTasksIncomplete}'),
              _buildStatItem(
                'Avg Completion',
                '${(analytics.averageCompletionTimeHours / 24).toStringAsFixed(1)} days',
              ),
              _buildStatItem('Active Members', '${analytics.members.length}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildPerformanceTable(TeamAnalytics analytics) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Metric', isHeader: true),
            _buildTableCell('Value', isHeader: true),
            _buildTableCell('Notes', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Task Breakdown'),
            _buildTableCell(
              'Completed: ${analytics.totalTasksCompleted} | Late: ${analytics.totalTasksLate} | Incomplete: ${analytics.totalTasksIncomplete}',
            ),
            _buildTableCell('From ${analytics.totalTasksAssigned} total tasks'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Performance Rates'),
            _buildTableCell(
              'Completion: ${analytics.completionRate.toStringAsFixed(1)}% | On-Time: ${analytics.onTimeRate.toStringAsFixed(1)}%',
            ),
            _buildTableCell('Higher is better'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Team Insights'),
            _buildTableCell(
              '${analytics.members.length} active members | Avg: ${(analytics.averageCompletionTimeHours / 24).toStringAsFixed(1)} days',
            ),
            _buildTableCell(
              'Last updated: ${_formatDate(analytics.lastUpdated)}',
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMemberLeaderboard(TeamAnalytics analytics) {
    final sortedMembers = analytics.members.values.toList()
      ..sort((a, b) => b.stats.completed.compareTo(a.stats.completed));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Rank', isHeader: true),
            _buildTableCell('Member', isHeader: true),
            _buildTableCell('Completed', isHeader: true),
            _buildTableCell('Late', isHeader: true),
            _buildTableCell('Incomplete', isHeader: true),
            _buildTableCell('Completion %', isHeader: true),
          ],
        ),
        ...sortedMembers.take(10).map((member) {
          final rank = sortedMembers.indexOf(member) + 1;
          return pw.TableRow(
            children: [
              _buildTableCell(rank <= 3 ? '🏆 $rank' : '$rank'),
              _buildTableCell(member.name),
              _buildTableCell('${member.stats.completed}'),
              _buildTableCell('${member.stats.late}'),
              _buildTableCell('${member.stats.incomplete}'),
              _buildTableCell(
                '${member.stats.completionRate.toStringAsFixed(1)}%',
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildMemberStatsGrid(MemberPerformance member) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          _buildStatItem('Assigned', '${member.stats.assigned}'),
          _buildStatItem('Completed', '${member.stats.completed}'),
          _buildStatItem('Late', '${member.stats.late}'),
          _buildStatItem('Incomplete', '${member.stats.incomplete}'),
          _buildStatItem(
            'Completion Rate',
            '${member.stats.completionRate.toStringAsFixed(1)}%',
          ),
          _buildStatItem(
            'On-Time Rate',
            '${member.stats.onTimeRate.toStringAsFixed(1)}%',
          ),
          _buildStatItem(
            'Avg Time',
            '${(member.stats.avgCompletionHours / 24).toStringAsFixed(1)} days',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTaskHistoryTable(MemberPerformance member) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Task', isHeader: true),
            _buildTableCell('Assigned', isHeader: true),
            _buildTableCell('Completed', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        ...member.recentTasks.take(20).map((task) {
          return pw.TableRow(
            children: [
              _buildTableCell(task.title, maxLines: 2),
              _buildTableCell(_formatDate(task.assignedAt)),
              _buildTableCell(
                task.completedAt != null ? _formatDate(task.completedAt!) : '-',
              ),
              _buildTableCell(_getStatusLabel(task.status)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    int maxLines = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return '✓ Done';
      case 'late':
        return '⚠ Late';
      case 'incomplete':
        return '✗ Incomplete';
      default:
        return '○ Pending';
    }
  }
}
