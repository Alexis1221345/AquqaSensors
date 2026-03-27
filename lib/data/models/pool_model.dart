class PoolModel {
  final String id;
  final String ownerId;
  final String nombre;
  final String? descripcion;
  final double? volumenLitros;
  final String? ubicacion;
  final String? tipo;
  final double? largoM;
  final double? anchoM;
  final double? diametroM;
  final double? profMinimaM;
  final double? profMaximaM;
  final List<String> imageUrls;
  final DateTime? creadaEn;

  const PoolModel({
    required this.id,
    required this.ownerId,
    required this.nombre,
    this.descripcion,
    this.volumenLitros,
    this.ubicacion,
    this.tipo,
    this.largoM,
    this.anchoM,
    this.diametroM,
    this.profMinimaM,
    this.profMaximaM,
    this.imageUrls = const [],
    this.creadaEn,
  });

  factory PoolModel.fromJson(Map<String, dynamic> json) {
    return PoolModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      volumenLitros: json['volumen_litros'] != null
          ? (json['volumen_litros'] as num).toDouble()
          : null,
      ubicacion: json['ubicacion'] as String?,
      tipo: json['tipo'] as String?,
      largoM: json['largo_m'] != null ? (json['largo_m'] as num).toDouble() : null,
      anchoM: json['ancho_m'] != null ? (json['ancho_m'] as num).toDouble() : null,
      diametroM:
          json['diametro_m'] != null ? (json['diametro_m'] as num).toDouble() : null,
      profMinimaM: json['prof_minima_m'] != null
          ? (json['prof_minima_m'] as num).toDouble()
          : null,
      profMaximaM: json['prof_maxima_m'] != null
          ? (json['prof_maxima_m'] as num).toDouble()
          : null,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : (json['imagen_url'] != null
              ? [json['imagen_url'] as String]
              : const []),
      creadaEn: json['creada_en'] != null
          ? DateTime.parse(json['creada_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'nombre': nombre,
      'descripcion': descripcion,
      'volumen_litros': volumenLitros,
      'ubicacion': ubicacion,
      'tipo': tipo,
      'largo_m': largoM,
      'ancho_m': anchoM,
      'diametro_m': diametroM,
      'prof_minima_m': profMinimaM,
      'prof_maxima_m': profMaximaM,
      'image_urls': imageUrls,
      'creada_en': creadaEn?.toIso8601String(),
    };
  }
}
