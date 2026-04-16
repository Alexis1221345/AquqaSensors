import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'stats_row.dart';
import 'download_pdf_button.dart';
import '../../home/widgets/bar_chart_widget.dart';

class ReportChartCard extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final Color color;
  final String unit;
  final double promedio;
  final double minimo;
  final double maximo;
  final List<double> chartValues;
  final List<String> chartLabels;
  final String selectedPeriod;
  final VoidCallback onDownload;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.rangeLabel,
    required this.color,
    required this.unit,
    required this.promedio,
    required this.minimo,
    required this.maximo,
    required this.chartValues,
    required this.chartLabels,
    required this.selectedPeriod,
    required this.onDownload,
  });

  String get _downloadLabel {
    final now = DateTime.now();
    final periodName = {
      'dia': 'Diario',
      'semana': 'Semanal',
      'quincenal': 'Quincenal',
      'mensual': 'Mensual',
    }[selectedPeriod]!;
    return '$periodName • ${DateFormatter.toDisplay(now)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(rangeLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Stats ─────────────────────────────────────────────────────────
          StatsRow(
            promedio: promedio,
            minimo: minimo,
            maximo: maximo,
            unit: unit,
          ),
          const SizedBox(height: 16),

          // ── Gráfica de barras ─────────────────────────────────────────────
          BarChartWidget(
            values: chartValues,
            barColor: color,
            labels: chartLabels,
          ),
          const SizedBox(height: 14),

          // ── Botón descargar ───────────────────────────────────────────────
          DownloadPdfButton(
            parameter: title,
            periodLabel: _downloadLabel,
            color: color,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}
