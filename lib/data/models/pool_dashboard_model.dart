class PoolAlertModel {
  final String id;
  final String parametro;
  final double valorDetectado;
  final String nivel;
  final String mensaje;
  final DateTime createdAt;

  const PoolAlertModel({
    required this.id,
    required this.parametro,
    required this.valorDetectado,
    required this.nivel,
    required this.mensaje,
    required this.createdAt,
  });

  factory PoolAlertModel.fromJson(Map<String, dynamic> json) => PoolAlertModel(
        id: json['id'] as String,
        parametro: json['parametro'] as String,
        valorDetectado: (json['valor_detectado'] as num).toDouble(),
        nivel: json['nivel'] as String,
        mensaje: json['mensaje'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ChemicalDoseHistoryModel {
  final String id;
  final String quimico;
  final double? cantidadGramos;
  final double? cantidadMl;
  final String? motivo;
  final DateTime timestamp;

  const ChemicalDoseHistoryModel({
    required this.id,
    required this.quimico,
    this.cantidadGramos,
    this.cantidadMl,
    this.motivo,
    required this.timestamp,
  });

  String get cantidadLabel {
    if (cantidadMl == null) return '—';
    return '${cantidadMl!.toStringAsFixed(0)} ml';
  }

  String get quimicoLabel =>
      {
        'cloro': 'Cloro',
        'tricloro': 'Tricloro',
        'cloro_choque': 'Cloro Choque',
        'algicida': 'Algicida',
        'subir_ph': 'Subir pH',
        'bajar_ph': 'Bajar pH',
        'alcalinidad': 'Alcalinidad',
        'turbidez': 'Floculante',
        'alcalinidad_plus_liquido': 'Alcalinidad Plus',
        'hipoclorito_sodio': 'Hipoclorito de sodio',
        'acido_muriatico': 'Ácido muriático',
        'soda_caustica': 'Soda cáustica',
        'floculante': 'Floculante',
        'antical': 'Antical',
      }[quimico] ??
      quimico;

  factory ChemicalDoseHistoryModel.fromJson(Map<String, dynamic> json) =>
      ChemicalDoseHistoryModel(
        id: json['id'] as String,
        quimico: json['quimico'] as String,
        cantidadGramos: json['cantidad_gramos'] != null
            ? (json['cantidad_gramos'] as num).toDouble()
            : null,
        cantidadMl: json['cantidad_ml'] != null
            ? (json['cantidad_ml'] as num).toDouble()
            : null,
        motivo: json['motivo'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class RecommendedDoseModel {
  final String quimico;
  final double cantidad;
  final String unidad;
  final String frecuencia;
  final String descripcion;

  const RecommendedDoseModel({
    required this.quimico,
    required this.cantidad,
    required this.unidad,
    required this.frecuencia,
    required this.descripcion,
  });

  String get cantidadLabel {
    if (unidad == 'ml' && cantidad >= 1000) {
      return '${(cantidad / 1000).toStringAsFixed(1)} L';
    }
    if (unidad == 'ml') {
      return '${cantidad.toStringAsFixed(0)} ml';
    }
    return '${cantidad.toStringAsFixed(0)} ml';
  }

  String get quimicoLabel =>
      {
        'cloro': 'Cloro',
        'tricloro': 'Tricloro',
        'cloro_choque': 'Cloro Choque',
        'algicida': 'Algicida',
        'subir_ph': 'Subir pH',
        'bajar_ph': 'Bajar pH',
        'alcalinidad': 'Alcalinidad',
        'turbidez': 'Floculante',
        'alcalinidad_plus_liquido': 'Alcalinidad Plus',
        'hipoclorito_sodio': 'Hipoclorito de sodio',
        'acido_muriatico': 'Ácido muriático',
        'soda_caustica': 'Soda cáustica',
        'floculante': 'Floculante',
        'antical': 'Antical',
      }[quimico] ??
      quimico;

  factory RecommendedDoseModel.fromJson(Map<String, dynamic> json) =>
      RecommendedDoseModel(
        quimico: json['quimico'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        unidad: json['unidad'] as String,
        frecuencia: json['frecuencia'] as String,
        descripcion: json['descripcion'] as String,
      );
}

class PoolDashboardPoolModel {
  final String id;
  final String nombre;
  final String? tipo;
  final double? volumenLitros;
  final String? ubicacion;

  const PoolDashboardPoolModel({
    required this.id,
    required this.nombre,
    this.tipo,
    this.volumenLitros,
    this.ubicacion,
  });

  factory PoolDashboardPoolModel.fromJson(Map<String, dynamic> json) =>
      PoolDashboardPoolModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        tipo: json['tipo'] as String?,
        volumenLitros: json['volumen_litros'] != null
            ? (json['volumen_litros'] as num).toDouble()
            : null,
        ubicacion: json['ubicacion'] as String?,
      );
}

class PoolDashboardModel {
  final PoolDashboardPoolModel? pool;
  final List<PoolAlertModel> alertasActivas;
  final List<ChemicalDoseHistoryModel> dosisHistorial;
  final List<RecommendedDoseModel> dosisRecomendadas;

  const PoolDashboardModel({
    required this.pool,
    required this.alertasActivas,
    required this.dosisHistorial,
    required this.dosisRecomendadas,
  });

  bool get tieneAlertas => alertasActivas.isNotEmpty;
  bool get tieneAlertasCriticas =>
      alertasActivas.any((a) => a.nivel == 'critico');
  int get totalCriticas =>
      alertasActivas.where((a) => a.nivel == 'critico').length;
  int get totalAlertas =>
      alertasActivas.where((a) => a.nivel == 'alerta').length;

  factory PoolDashboardModel.fromJson(Map<String, dynamic> json) =>
      PoolDashboardModel(
        pool: json['pool'] != null
            ? PoolDashboardPoolModel.fromJson(
                json['pool'] as Map<String, dynamic>,
              )
            : null,
        alertasActivas: ((json['alertas_activas'] as List?) ?? const [])
            .map((e) => PoolAlertModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        dosisHistorial: ((json['dosis_historial'] as List?) ?? const [])
            .map((e) =>
                ChemicalDoseHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        dosisRecomendadas: ((json['dosis_recomendadas'] as List?) ?? const [])
            .map(
                (e) => RecommendedDoseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
