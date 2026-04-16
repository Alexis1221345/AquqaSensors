class PoolChemicalModel {
  final String? id;
  final String poolId;
  final String categoria;
  final String quimicoId;
  final String quimicoNombre;
  final double concentracion;
  final bool activo;

  const PoolChemicalModel({
    this.id,
    required this.poolId,
    required this.categoria,
    required this.quimicoId,
    required this.quimicoNombre,
    required this.concentracion,
    this.activo = true,
  });

  factory PoolChemicalModel.fromJson(Map<String, dynamic> json) {
    return PoolChemicalModel(
      id: json['id'] as String?,
      poolId: json['pool_id'] as String,
      categoria: json['categoria'] as String,
      quimicoId: json['quimico_id'] as String,
      quimicoNombre: json['quimico_nombre'] as String,
      concentracion: (json['concentracion'] as num).toDouble(),
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pool_id': poolId,
      'categoria': categoria,
      'quimico_id': quimicoId,
      'quimico_nombre': quimicoNombre,
      'concentracion': concentracion,
      'activo': activo,
    };
  }

  PoolChemicalModel copyWith({
    String? id,
    String? poolId,
    String? categoria,
    String? quimicoId,
    String? quimicoNombre,
    double? concentracion,
    bool? activo,
  }) {
    return PoolChemicalModel(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      categoria: categoria ?? this.categoria,
      quimicoId: quimicoId ?? this.quimicoId,
      quimicoNombre: quimicoNombre ?? this.quimicoNombre,
      concentracion: concentracion ?? this.concentracion,
      activo: activo ?? this.activo,
    );
  }
}

class ChemicalOption {
  final String id;
  final String nombre;
  final List<double> concentraciones;

  const ChemicalOption(this.id, this.nombre, this.concentraciones);
}

class ChemicalCatalog {
  ChemicalCatalog._();

  static const Map<String, List<ChemicalOption>> byCategoria = {
    'cloro': [
      ChemicalOption(
        'hipoclorito_sodio',
        'Hipoclorito de sodio',
        [10, 12, 15],
      ),
      ChemicalOption(
        'hipoclorito_calcio_liq',
        'Hipoclorito de calcio líquido',
        [10, 15],
      ),
      ChemicalOption(
        'dioxido_cloro',
        'Dióxido de cloro',
        [0.8, 1],
      ),
    ],
    'bajar_ph': [
      ChemicalOption(
        'acido_muriatico',
        'Ácido muriático (HCl)',
        [28, 31, 33],
      ),
      ChemicalOption(
        'acido_sulfurico',
        'Ácido sulfúrico',
        [33, 50, 66],
      ),
      ChemicalOption(
        'acido_citrico_liq',
        'Ácido cítrico líquido',
        [50],
      ),
    ],
    'subir_ph': [
      ChemicalOption(
        'soda_caustica',
        'Soda cáustica (NaOH)',
        [30, 40, 50],
      ),
      ChemicalOption(
        'carbonato_sodio_liq',
        'Carbonato de sodio líquido',
        [20, 30],
      ),
      ChemicalOption(
        'bicarbonato_liquido',
        'Bicarbonato líquido',
        [25, 40],
      ),
    ],
    'alcalinidad': [
      ChemicalOption(
        'alcalinidad_plus_liquido',
        'Alcalinidad plus líquido',
        [25, 30, 40],
      ),
      ChemicalOption(
        'soda_caustica',
        'Soda cáustica (NaOH)',
        [30, 40, 50],
      ),
    ],
    'turbidez': [
      ChemicalOption('floculante', 'Floculante líquido', [10, 20, 40]),
    ],
    'algicida': [
      ChemicalOption('algicida', 'Algicida líquido', [10, 40, 60]),
    ],
  };

  static const Map<String, String> categoriaLabel = {
    'cloro': 'Cloro',
    'bajar_ph': 'Bajar pH',
    'subir_ph': 'Subir pH',
    'alcalinidad': 'Alcalinidad',
    'turbidez': 'Turbidez / Floculante',
    'algicida': 'Algicida',
  };
}
