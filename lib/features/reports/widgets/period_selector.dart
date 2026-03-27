import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const List<_Period> _periods = [
    _Period('dia', 'Día'),
    _Period('semana', 'Semana'),
    _Period('quincenal', 'Quincenal'),
    _Period('mensual', 'Mensual'),
  ];

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _periods.map((p) {
        final isSelected = selected == p.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(p.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                p.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Period {
  final String value;
  final String label;

  const _Period(this.value, this.label);
}
