import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'period_selector.dart';
import 'stats_row.dart';
import 'download_pdf_button.dart';
import '../../home/widgets/bar_chart_widget.dart';

class ReportChartCard extends StatefulWidget {
  final String title;
  final String rangeLabel;
  final Color color;
  final String unit;
  final Future<void> Function(String period, DateTime from, DateTime to) onPeriodChanged;
  final double promedio;
  final double minimo;
  final double maximo;
  final List<double> chartValues;
  final List<String> chartLabels;
  final VoidCallback onDownload;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.rangeLabel,
    required this.color,
    required this.unit,
    required this.onPeriodChanged,
    required this.promedio,
    required this.minimo,
    required this.maximo,
    required this.chartValues,
    required this.chartLabels,
    required this.onDownload,
  });

  @override
  State<ReportChartCard> createState() => _ReportChartCardState();
}

class _ReportChartCardState extends State<ReportChartCard> {
  String _selectedPeriod = 'dia';

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    final now = DateTime.now();
    final from = _periodFrom(period, now);
    widget.onPeriodChanged(period, from, now);
  }

  DateTime _periodFrom(String period, DateTime now) {
    switch (period) {
      case 'semana':
        return now.subtract(const Duration(days: 7));
      case 'quincenal':
        return now.subtract(const Duration(days: 15));
      case 'mensual':
        return now.subtract(const Duration(days: 30));
      default: // dia
        return DateTime(now.year, now.month, now.day);
    }
  }

  String get _downloadLabel {
    final now = DateTime.now();
    final periodName = {
      'dia': 'Diario',
      'semana': 'Semanal',
      'quincenal': 'Quincenal',
      'mensual': 'Mensual',
    }[_selectedPeriod]!;
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
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(widget.rangeLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Selector de período ───────────────────────────────────────────
          PeriodSelector(
            selected: _selectedPeriod,
            onChanged: _onPeriodChanged,
          ),
          const SizedBox(height: 16),

          // ── Stats ─────────────────────────────────────────────────────────
          StatsRow(
            promedio: widget.promedio,
            minimo: widget.minimo,
            maximo: widget.maximo,
            unit: widget.unit,
          ),
          const SizedBox(height: 16),

          // ── Gráfica de barras ─────────────────────────────────────────────
          BarChartWidget(
            values: widget.chartValues,
            barColor: widget.color,
            labels: widget.chartLabels,
          ),
          const SizedBox(height: 14),

          // ── Botón descargar ───────────────────────────────────────────────
          DownloadPdfButton(
            parameter: widget.title,
            periodLabel: _downloadLabel,
            color: widget.color,
            onTap: widget.onDownload,
          ),
        ],
      ),
    );
  }
}
