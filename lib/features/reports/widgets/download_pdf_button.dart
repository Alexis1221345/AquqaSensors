import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DownloadPdfButton extends StatelessWidget {
  final String parameter;  // ej. "pH"
  final String periodLabel; // ej. "Diario • 9/3/2026"
  final Color color;
  final VoidCallback onTap;

  const DownloadPdfButton({
    super.key,
    required this.parameter,
    required this.periodLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.download_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descargar PDF – $parameter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  periodLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
