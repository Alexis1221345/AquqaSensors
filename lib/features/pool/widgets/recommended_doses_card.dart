import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pool_dashboard_model.dart';

class RecommendedDosesCard extends StatelessWidget {
  final List<RecommendedDoseModel> dosis;
  final double? volumenLitros;

  const RecommendedDosesCard({
    super.key,
    required this.dosis,
    this.volumenLitros,
  });

  String get _volumenLabel {
    if (volumenLitros == null) return '';
    if (volumenLitros! >= 1000000) {
      return '${(volumenLitros! / 1000000).toStringAsFixed(2)} ML';
    }
    if (volumenLitros! >= 1000) {
      return '${(volumenLitros! / 1000).toStringAsFixed(0)} m³';
    }
    return '${volumenLitros!.toStringAsFixed(0)} L';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dosis recomendadas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (volumenLitros != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _volumenLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Calculadas automáticamente por Supabase según el volumen',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ...dosis.map((d) => _RecommendedRow(dosis: d)),
          ],
        ),
      ),
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  final RecommendedDoseModel dosis;

  const _RecommendedRow({required this.dosis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dosis.quimicoLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dosis.descripcion,
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dosis.cantidadLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                dosis.frecuencia,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

