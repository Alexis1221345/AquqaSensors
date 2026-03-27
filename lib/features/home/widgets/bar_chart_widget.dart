import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Mini gráfica de barras que muestra la variación del parámetro durante el día.
/// [values] es una lista de 0.0–1.0 (normalizados).
/// [barColor] es el color de las barras (ej. AppColors.ph).
class BarChartWidget extends StatelessWidget {
  final List<double> values;
  final Color barColor;
  final List<String>? labels; // etiquetas del eje X (ej. ["2h","9h","15h","20h"])

  const BarChartWidget({
    super.key,
    required this.values,
    required this.barColor,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((entry) {
              final normalized = entry.value.clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: 8 + normalized * 40,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.75),
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

    // Muestra máximo 5 etiquetas distribuidas
    final step = (values.length / (labels!.length - 1)).ceil();
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
