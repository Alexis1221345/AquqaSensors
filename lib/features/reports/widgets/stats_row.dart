import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final double promedio;
  final double minimo;
  final double maximo;
  final String unit;

  const StatsRow({
    super.key,
    required this.promedio,
    required this.minimo,
    required this.maximo,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(label: 'Promedio', value: promedio, unit: unit),
        _StatCell(label: 'Mínimo', value: minimo, unit: unit),
        _StatCell(label: 'Máximo', value: maximo, unit: unit),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(value)}$unit',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
