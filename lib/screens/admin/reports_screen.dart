import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/glass_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format selected date
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    // Mock data based on selected date
    final servedCount = 42 + (_selectedDate.day % 7) * 3;
    final cancelledCount = 4 + (_selectedDate.day % 5);
    final avgWaitTime = 12.5 + (_selectedDate.day % 4) * 1.5;
    final efficiencyRate = 92 - (_selectedDate.day % 3) * 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Analytics & Reports'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selector Row
              _buildDateSelector(dateStr),
              const SizedBox(height: Spacing.s24),

              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Served',
                      servedCount.toString(),
                      Icons.people_outline_rounded,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: Spacing.s12),
                  Expanded(
                    child: _buildMetricCard(
                      'Cancelled',
                      cancelledCount.toString(),
                      Icons.cancel_outlined,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.s12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Avg Wait Time',
                      '${avgWaitTime.toStringAsFixed(0)} mins',
                      Icons.access_time_rounded,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: Spacing.s12),
                  Expanded(
                    child: _buildMetricCard(
                      'Efficiency Rate',
                      '$efficiencyRate%',
                      Icons.offline_bolt_rounded,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.s32),

              // Hourly Traffic Chart
              Text(
                'Hourly Queue Traffic',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Spacing.s16),
              _buildTrafficChart(),
              const SizedBox(height: Spacing.s32),

              // Top Services breakdown
              Text(
                'Service Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Spacing.s16),
              _buildServiceDistribution(servedCount),
              const SizedBox(height: Spacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String formattedDate) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s16, vertical: Spacing.s12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: Spacing.s12),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              Icon(icon, color: color.withValues(alpha: 0.6), size: 18),
            ],
          ),
          const SizedBox(height: Spacing.s8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficChart() {
    return GlassCard(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tokens Issued by Hour',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Spacing.s24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        switch (value.toInt()) {
                          case 9:
                            text = '9 AM';
                            break;
                          case 11:
                            text = '11 AM';
                            break;
                          case 13:
                            text = '1 PM';
                            break;
                          case 15:
                            text = '3 PM';
                            break;
                          case 17:
                            text = '5 PM';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 9,
                maxX: 17,
                minY: 0,
                maxY: 50,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(9, 8),
                      FlSpot(10, 18),
                      FlSpot(11, 35),
                      FlSpot(12, 42),
                      FlSpot(13, 24),
                      FlSpot(14, 31),
                      FlSpot(15, 38),
                      FlSpot(16, 20),
                      FlSpot(17, 10),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDistribution(int servedCount) {
    // Generate some mock distribution percentages
    final list = [
      {'name': 'Account Services', 'percentage': 45},
      {'name': 'Cash Deposits', 'percentage': 30},
      {'name': 'Loan Inquiry', 'percentage': 15},
      {'name': 'Other Requests', 'percentage': 10},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(Spacing.s20),
      child: Column(
        children: list.map((item) {
          final pct = item['percentage'] as int;
          final count = (servedCount * pct) ~/ 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$count served ($pct%)',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
