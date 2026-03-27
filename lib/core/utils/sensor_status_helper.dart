import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';

enum SensorStatus { optimo, alerta, critico }

class SensorStatusHelper {
  SensorStatusHelper._();

  // ── Evalúa el status de cada parámetro ───────────────────────────────────

  static SensorStatus phStatus(double value) {
    if (value >= AppConstants.phMin && value <= AppConstants.phMax) {
      return SensorStatus.optimo;
    } else if (value >= AppConstants.phAbsMin && value <= AppConstants.phAbsMax) {
      return SensorStatus.alerta;
    }
    return SensorStatus.critico;
  }

  static SensorStatus cloroStatus(double value) {
    if (value >= AppConstants.cloroMin && value <= AppConstants.cloroMax) {
      return SensorStatus.optimo;
    } else if (value >= AppConstants.cloroAbsMin && value <= AppConstants.cloroAbsMax) {
      return SensorStatus.alerta;
    }
    return SensorStatus.critico;
  }

  static SensorStatus temperaturaStatus(double value) {
    if (value >= AppConstants.tempMin && value <= AppConstants.tempMax) {
      return SensorStatus.optimo;
    } else if (value >= AppConstants.tempAbsMin && value <= AppConstants.tempAbsMax) {
      return SensorStatus.alerta;
    }
    return SensorStatus.critico;
  }

  static SensorStatus turbidezStatus(double value) {
    if (value <= AppConstants.turbidezMax) return SensorStatus.optimo;
    if (value <= AppConstants.turbidezAbsMax) return SensorStatus.alerta;
    return SensorStatus.critico;
  }

  // ── Convierte a texto legible ─────────────────────────────────────────────

  static String statusLabel(SensorStatus status) {
    switch (status) {
      case SensorStatus.optimo:
        return 'Óptimo';
      case SensorStatus.alerta:
        return 'Alerta';
      case SensorStatus.critico:
        return 'Crítico';
    }
  }

  // ── Color del badge ───────────────────────────────────────────────────────

  static Color statusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.optimo:
        return AppColors.statusOptimo;
      case SensorStatus.alerta:
        return AppColors.statusAlerta;
      case SensorStatus.critico:
        return AppColors.statusCritico;
    }
  }

  // ── Normaliza un valor entre 0.0 y 1.0 para el gauge ─────────────────────
  // absMin y absMax son los límites del arco completo del tacómetro

  static double normalizeForGauge(double value, double absMin, double absMax) {
    if (absMax == absMin) return 0.0;
    final normalized = (value - absMin) / (absMax - absMin);
    return normalized.clamp(0.0, 1.0);
  }

  // ── Color del arco del tacómetro según posición normalizada ───────────────

  static Color gaugeColor(double normalized) {
    if (normalized <= 0.4) return AppColors.gaugeGood;
    if (normalized <= 0.7) return AppColors.gaugeWarning;
    return AppColors.gaugeDanger;
  }
}
