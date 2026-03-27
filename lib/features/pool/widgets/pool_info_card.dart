import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pool_model.dart';
import 'pool_3d_preview.dart';

class PoolInfoCard extends StatelessWidget {
  final PoolModel pool;

  const PoolInfoCard({super.key, required this.pool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Galería de imágenes (Supabase Storage)
          if (pool.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                child: PageView.builder(
                  itemCount: pool.imageUrls.length,
                  itemBuilder: (_, i) => Image.network(
                    pool.imageUrls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Pool3dPreview(
                largoM: pool.largoM,
                anchoM: pool.anchoM,
                diametroM: pool.diametroM,
                profMinimaM: pool.profMinimaM,
                profMaximaM: pool.profMaximaM,
              ),
            ),

          // Datos de la alberca
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pool.nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (pool.descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(pool.descripcion!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                _infoChip(Icons.water_outlined,
                    pool.volumenLitros != null
                        ? '${pool.volumenLitros!.toStringAsFixed(0)} L'
                        : 'Volumen desconocido'),
                const SizedBox(height: 6),
                _infoChip(Icons.straighten,
                    _dimensionsLabel(pool)),
                const SizedBox(height: 6),
                if (pool.ubicacion != null)
                  _infoChip(Icons.location_on_outlined, pool.ubicacion!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  String _dimensionsLabel(PoolModel pool) {
    final largo = pool.largoM ?? pool.diametroM;
    final ancho = pool.anchoM ?? pool.diametroM;
    final pMin = pool.profMinimaM;
    final pMax = pool.profMaximaM;

    if (largo == null || ancho == null || pMin == null || pMax == null) {
      return 'Medidas no disponibles';
    }

    return '${_fmt(largo)}m x ${_fmt(ancho)}m x ${_fmt(pMin)}-${_fmt(pMax)}m';
  }

  String _fmt(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? value.toStringAsFixed(0) : fixed;
  }
}
