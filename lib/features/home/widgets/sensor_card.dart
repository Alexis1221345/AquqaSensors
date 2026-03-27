import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sensor_status_helper.dart';
import 'gauge_widget.dart';
import 'bar_chart_widget.dart';
import 'status_badge.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double value;
  final String unit;
  final String rangeLabel;
  final SensorStatus status;
  final double gaugeNormalized;
  final List<double> dailyValues;
  final List<String> dailyLabels;

  const SensorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.rangeLabel,
    required this.status,
    required this.gaugeNormalized,
    required this.dailyValues,
    required this.dailyLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título + badge ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 6),
                    Text(title, style: AppTextStyles.heading3),
                  ],
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            // ── Tacómetro + valor centrados ────────────────────────────
            Center(
              child: Column(
                children: [
                  GaugeWidget(value: gaugeNormalized, size: 180),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _fmt(value),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: unit,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(rangeLabel, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Mini gráfica ───────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Variación hoy',
                    style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            BarChartWidget(
              values: dailyValues,
              barColor: iconColor,
              labels: dailyLabels,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}