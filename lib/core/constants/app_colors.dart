import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primarios — azul del header
  static const Color primary = Color(0xFF1A6B8A);
  static const Color primaryDark = Color(0xFF0F4D66);
  static const Color primaryLight = Color(0xFF2D8FAD);

  // Fondo
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);

  // Tacómetro — arco de niveles
  static const Color gaugeGood = Color(0xFF4CAF50);     // verde: nivel óptimo
  static const Color gaugeWarning = Color(0xFFFFC107);  // amarillo: precaución
  static const Color gaugeDanger = Color(0xFFF44336);   // rojo: crítico

  // Status badges
  static const Color statusOptimo = Color(0xFF4CAF50);
  static const Color statusAlerta = Color(0xFFFFC107);
  static const Color statusCritico = Color(0xFFF44336);

  // Parámetros (colores de barras en reportes)
  static const Color ph = Color(0xFF2196F3);         // azul
  static const Color cloro = Color(0xFF4CAF50);      // verde
  static const Color temperatura = Color(0xFFFF9800); // naranja
  static const Color turbidez = Color(0xFF9C27B0);   // morado

  // Texto
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  // Bordes
  static const Color border = Color(0xFFE5E7EB);
}
