import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Mini gráfica de barras que muestra la variación del parámetro durante el día.
/// [values] es una lista de 0.0–1.0 (normalizados).
/// [barColor] es el color de las barras (ej. AppColors.ph).
class BarChartWidget extends StatelessWidget {
  final List<double> values;
  final Color barColor;
  final List<String>? labels; // etiquetas del eje X (ej. ["2h","9h","15h","20h"])
  final int maxBars;

  const BarChartWidget({
    super.key,
    required this.values,
    required this.barColor,
    this.labels,
    this.maxBars = 60,
  });

  List<double> _downsample(List<double> input, int target) {
    if (input.length <= target) return input;

    final result = <double>[];
    final step = input.length / target;

    for (var i = 0; i < target; i++) {
      final start = (i * step).floor();
      final rawEnd = ((i + 1) * step).floor();
      final end = rawEnd <= start
          ? (start + 1).clamp(0, input.length)
          : rawEnd.clamp(0, input.length);
      final chunk = input.sublist(start, end);
      final avg = chunk.reduce((a, b) => a + b) / chunk.length;
      result.add(avg);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final displayValues = _downsample(values, maxBars);

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayValues.asMap().entries.map((entry) {
              final normalized = entry.value.clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: 8 + normalized * 40,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (labels != null && labels!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildLabels(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildLabels() {
    if (labels == null || labels!.isEmpty) return [];
    return labels!.map((l) {
      return Text(
        l,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      );
    }).toList();
  }
}
