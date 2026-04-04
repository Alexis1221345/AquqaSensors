import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pool_dashboard_model.dart';

class ActiveAlertsCard extends StatelessWidget {
  final List<PoolAlertModel> alertas;

  const ActiveAlertsCard({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertas.any((a) => a.nivel == 'critico')
              ? AppColors.statusCritico.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  alertas.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.notifications_active_outlined,
                  size: 16,
                  color: alertas.isEmpty
                      ? AppColors.statusOptimo
                      : AppColors.statusCritico,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Alertas activas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (alertas.isNotEmpty) _AlertCountBadge(alertas: alertas),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Todos los parámetros en rango óptimo ✓',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.statusOptimo,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              itemCount: alertas.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) => _AlertRow(alerta: alertas[i]),
            ),
        ],
      ),
    );
  }
}

class _AlertCountBadge extends StatelessWidget {
  final List<PoolAlertModel> alertas;

  const _AlertCountBadge({required this.alertas});

  @override
  Widget build(BuildContext context) {
    final criticas = alertas.where((a) => a.nivel == 'critico').length;
    final normales = alertas.where((a) => a.nivel == 'alerta').length;
    return Row(
      children: [
        if (criticas > 0)
          _Badge(count: criticas, color: AppColors.statusCritico),
        if (criticas > 0 && normales > 0) const SizedBox(width: 4),
        if (normales > 0)
          _Badge(count: normales, color: AppColors.statusAlerta),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;

  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final PoolAlertModel alerta;

  const _AlertRow({required this.alerta});

  Color get _color =>
      alerta.nivel == 'critico' ? AppColors.statusCritico : AppColors.statusAlerta;

  IconData get _icon => alerta.nivel == 'critico'
      ? Icons.error_outline
      : Icons.warning_amber_outlined;

  String get _tiempo {
    final diff = DateTime.now().difference(alerta.createdAt.toLocal());
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alerta.parametro.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alerta.nivel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  alerta.mensaje,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _tiempo,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

