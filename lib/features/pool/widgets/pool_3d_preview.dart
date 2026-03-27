import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Pool3dPreview — SVG vectorial 100 % basado en medidas reales.
//  Sin CustomPainter, sin rasters → escala perfectamente en cualquier DPI.
// ─────────────────────────────────────────────────────────────────────────────

class Pool3dPreview extends StatelessWidget {
  final double? largoM;
  final double? anchoM;
  final double? diametroM;
  final double? profMinimaM;
  final double? profMaximaM;
  final double height;
  final bool showDimensionBadge;

  const Pool3dPreview({
    super.key,
    this.largoM,
    this.anchoM,
    this.diametroM,
    this.profMinimaM,
    this.profMaximaM,
    this.height = 250,
    this.showDimensionBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final largo   = (largoM   ?? diametroM ?? 10).clamp(1.0, 60.0);
    final ancho   = (anchoM   ?? diametroM ??  5).clamp(1.0, 60.0);
    final profMin = (profMinimaM ?? 1.2).clamp(0.4, 6.0);
    final profMax = (profMaximaM ?? profMin).clamp(profMin, 8.0);
    final profMed = (profMin + profMax) / 2;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── SVG vectorial — sin pixelación ──────────────────────────────
          Positioned.fill(
            child: SvgPicture.string(
              _Pool3dSvg.build(
                largo: largo,
                ancho: ancho,
                profMin: profMin,
                profMax: profMax,
              ),
              fit: BoxFit.contain,
            ),
          ),

          // ── Etiqueta de dimensiones (Flutter widget) ─────────────────────
          if (showDimensionBadge)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
                child: Text(
                  '${_fmt(largo)} m × ${_fmt(ancho)} m × ${_fmt(profMed)} m',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toStringAsFixed(0) : s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Generador de SVG isométrico (18 ° — vista lateral)
// ─────────────────────────────────────────────────────────────────────────────

class _Pool3dSvg {
  _Pool3dSvg._();

  static const double _vw  = 400;
  static const double _vh  = 300;
  static const double _ang = 18 * math.pi / 180;
  static final double _ca  = math.cos(_ang); // cos 18°
  static final double _sa  = math.sin(_ang); // sin 18°

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Número a string con 2 decimales.
  static String _n(double v) => v.toStringAsFixed(2);

  /// Proyección isométrica 3D → 2D pantalla.
  static (double, double) _proj(
    double W, double D, double H,
    double x, double y, double z,
  ) =>
      (
        _vw / 2 + x * _ca * W - y * _ca * D,
        _vh * 0.46 + x * _sa * W + y * _sa * D - z * H,
      );

  /// Lista de vértices → cadena "x1,y1 L x2,y2 L ..." lista para <path>.
  static String _pathPts(List<(double, double)> pts) =>
      pts.map((p) => '${_n(p.$1)},${_n(p.$2)}').join(' L ');

  /// Lista de vértices → cadena "x1,y1 x2,y2 ..." para <polygon points>.
  static String _polyPts(List<(double, double)> pts) =>
      pts.map((p) => '${_n(p.$1)},${_n(p.$2)}').join(' ');

  // ── Constructor principal ──────────────────────────────────────────────────

  static String build({
    required double largo,
    required double ancho,
    required double profMin,
    required double profMax,
  }) {
    final profMed = (profMin + profMax) / 2;

    // Escala adaptativa
    final maxDim = math.max(largo, ancho);
    final s =
        ((_vw * 0.34) / maxDim.clamp(1.0, 30.0)).clamp(6.0, 26.0);

    final W = (largo * s).clamp(90.0, _vw * 0.78);  // ancho en pantalla
    final D = (ancho * s * 0.58).clamp(36.0, _vw * 0.46); // profundidad
    final H = (profMed * s * 2.9).clamp(38.0, _vh * 0.54); // altura paredes

    // Función de proyección con escala actual
    (double, double) v(double x, double y, double z) =>
        _proj(W, D, H, x, y, z);

    // ── 7 vértices visibles ────────────────────────────────────────────────
    final tfl = v(0, 0, 1); // top-front-left
    final tfr = v(1, 0, 1); // top-front-right
    final tbr = v(1, 1, 1); // top-back-right
    final tbl = v(0, 1, 1); // top-back-left
    final bfl = v(0, 0, 0); // bottom-front-left
    final bfr = v(1, 0, 0); // bottom-front-right
    final bbr = v(1, 1, 0); // bottom-back-right

    // ── Deck / coping (borde de la alberca) ───────────────────────────────
    const dk = 7.0;
    final dtfl = (tfl.$1 - dk * _ca, tfl.$2 - dk * _sa);
    final dtfr = (tfr.$1 + dk * _ca, tfr.$2 - dk * _sa);
    final dtbr = (tbr.$1 + dk * _ca, tbr.$2 + dk * _sa);
    final dtbl = (tbl.$1 - dk * _ca, tbl.$2 + dk * _sa);

    // Deck como path evenodd (anillo = exterior sin interior del agua)
    final deckD =
        'M ${_pathPts([dtfl, dtfr, dtbr, dtbl])} Z '
        'M ${_pathPts([tfl, tfr, tbr, tbl])} Z';

    // ── Sombra elíptica ────────────────────────────────────────────────────
    final sCx = (bfl.$1 + bfr.$1 + bbr.$1 + tbl.$1) / 4 + 5;
    final sCy = (bfl.$2 + bfr.$2 + bbr.$2 + tbl.$2) / 4 + 17;
    final sRx = (W * _ca * 0.72).abs();
    final sRy = (D * _sa * 0.82).abs().clamp(8.0, 40.0);

    // ── Trama binarizada (líneas negras suaves sobre agua) ─────────────────
    final binaryLines = StringBuffer();
    for (int i = 0; i < 7; i++) {
      final t = (i + 1) / 8.0;

      final leftX = tfl.$1 * (1 - t) + tbl.$1 * t;
      final leftY = tfl.$2 * (1 - t) + tbl.$2 * t;
      final rightX = tfr.$1 * (1 - t) + tbr.$1 * t;
      final rightY = tfr.$2 * (1 - t) + tbr.$2 * t;

      final dx = (tbr.$1 - tfl.$1) * 0.16;
      final dy = (tbr.$2 - tfl.$2) * 0.16;

      binaryLines.writeln(
        '<line x1="${_n(leftX + dx)}" y1="${_n(leftY + dy)}" '
        'x2="${_n(rightX - dx)}" y2="${_n(rightY - dy)}" '
        'stroke="#000000" stroke-opacity="0.42" '
        'stroke-width="1.5" stroke-linecap="round" filter="url(#softBlack)"/>',
      );
    }

    // ── SVG final ─────────────────────────────────────────────────────────
    return '''<svg viewBox="0 0 ${_n(_vw)} ${_n(_vh)}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="softBlack" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="0.55"/>
    </filter>
    <clipPath id="waterClip">
      <polygon points="${_polyPts([tfl, tfr, tbr, tbl])}"/>
    </clipPath>
  </defs>

  <!-- 1. Sombra elíptica suave bajo la alberca -->
  <ellipse cx="${_n(sCx)}" cy="${_n(sCy)}"
    rx="${_n(sRx)}" ry="${_n(sRy)}"
    fill="#000000" fill-opacity="0.22"/>

  <!-- 2. Cara lateral derecha -->
  <polygon points="${_polyPts([tfr, tbr, bbr, bfr])}" fill="#164A73"/>

  <!-- 3. Cara frontal -->
  <polygon points="${_polyPts([tfl, tfr, bfr, bfl])}" fill="#216899"/>

  <!-- 4. Deck / coping (anillo alrededor del agua, evenodd) -->
  <path d="$deckD" fill="#CBDFEE" fill-rule="evenodd"/>

  <!-- 5. Superficie del agua -->
  <polygon points="${_polyPts([tfl, tfr, tbr, tbl])}" fill="#79D9FF"/>

  <!-- 6. Binarización: líneas negras desenfocadas sobre el agua -->
  <g clip-path="url(#waterClip)">
    ${binaryLines.toString().trim()}
  </g>

  <!-- 7. Arista superior (highlight) -->
  <polygon points="${_polyPts([tfl, tfr, tbr, tbl])}"
    fill="none" stroke="#7EC8F0" stroke-width="1.8" stroke-linejoin="round"/>

  <!-- 8. Aristas verticales visibles -->
  <line x1="${_n(tfl.$1)}" y1="${_n(tfl.$2)}"
    x2="${_n(bfl.$1)}" y2="${_n(bfl.$2)}"
    stroke="#5598C0" stroke-opacity="0.80" stroke-width="1.3"/>
  <line x1="${_n(tfr.$1)}" y1="${_n(tfr.$2)}"
    x2="${_n(bfr.$1)}" y2="${_n(bfr.$2)}"
    stroke="#5598C0" stroke-opacity="0.80" stroke-width="1.3"/>
  <line x1="${_n(tbr.$1)}" y1="${_n(tbr.$2)}"
    x2="${_n(bbr.$1)}" y2="${_n(bbr.$2)}"
    stroke="#5598C0" stroke-opacity="0.80" stroke-width="1.3"/>
</svg>''';
  }
}
