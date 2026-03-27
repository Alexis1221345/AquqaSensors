class SensorReading {
  final String id;
  final String poolId;
  final double ph;
  final double cloro;       // ppm
  final double temperatura; // °C
  final double turbidez;    // NTU
  final DateTime timestamp;
  final String? source;     // 'esp32' | 'manual'

  const SensorReading({
    required this.id,
    required this.poolId,
    required this.ph,
    required this.cloro,
    required this.temperatura,
    required this.turbidez,
    required this.timestamp,
    this.source,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] as String,
      poolId: json['pool_id'] as String,
      ph: (json['ph'] as num).toDouble(),
      cloro: (json['cloro'] as num).toDouble(),
      temperatura: (json['temperatura'] as num).toDouble(),
      turbidez: (json['turbidez'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pool_id': poolId,
      'ph': ph,
      'cloro': cloro,
      'temperatura': temperatura,
      'turbidez': turbidez,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  SensorReading copyWith({
    String? id,
    String? poolId,
    double? ph,
    double? cloro,
    double? temperatura,
    double? turbidez,
    DateTime? timestamp,
    String? source,
  }) {
    return SensorReading(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      ph: ph ?? this.ph,
      cloro: cloro ?? this.cloro,
      temperatura: temperatura ?? this.temperatura,
      turbidez: turbidez ?? this.turbidez,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }
}
