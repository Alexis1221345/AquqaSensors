class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String? empresa;
  final String rol;
  final String? avatarUrl;
  final DateTime? miembroDesde;
  final DateTime? ultimaSesion;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    this.empresa,
    this.rol = 'usuario',
    this.avatarUrl,
    this.miembroDesde,
    this.ultimaSesion,
  });

  String get nombreCompleto => '$nombre $apellido';

  /// Iniciales para el avatar (ej. "EG")
  String get initials {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$n$a';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      empresa: json['empresa'] as String?,
      rol: json['rol'] as String? ?? 'usuario',
      avatarUrl: json['avatar_url'] as String?,
      miembroDesde: json['miembro_desde'] != null
          ? DateTime.parse(json['miembro_desde'] as String)
          : null,
      ultimaSesion: json['ultima_sesion'] != null
          ? DateTime.parse(json['ultima_sesion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'empresa': empresa,
      'rol': rol,
      'avatar_url': avatarUrl,
      'miembro_desde': miembroDesde?.toIso8601String(),
      'ultima_sesion': ultimaSesion?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? empresa,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      empresa: empresa ?? this.empresa,
      rol: rol,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      miembroDesde: miembroDesde,
      ultimaSesion: ultimaSesion,
    );
  }
}
