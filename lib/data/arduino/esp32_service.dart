// TODO: Integración con chip Arduino ESP32
// Este servicio se comunica con el ESP32 vía HTTP (WiFi local).
// El ESP32 expone un servidor HTTP simple que devuelve lecturas de sensores.
//
// Endpoints esperados en el ESP32:
//   GET /sensors  → { ph, cloro, temperatura, turbidez, timestamp }
//   GET /status   → { connected, uptime, ip }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/sensor_reading.dart';

class Esp32Service {
  String _ip;
  final int _port;

  Esp32Service({
    String ip = AppConstants.esp32DefaultIp,
    int port = AppConstants.esp32Port,
  })  : _ip = ip,
        _port = port;

  String get baseUrl => 'http://$_ip:$_port';

  void updateIp(String newIp) => _ip = newIp;

  /// Obtiene las lecturas actuales del ESP32
  Future<SensorReading?> fetchReadings({required String poolId}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.esp32EndpointReadings}');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SensorReading(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          poolId: poolId,
          ph: (json['ph'] as num).toDouble(),
          cloro: (json['cloro'] as num).toDouble(),
          temperatura: (json['temperatura'] as num).toDouble(),
          turbidez: (json['turbidez'] as num).toDouble(),
          timestamp: json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
          source: 'esp32',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Verifica si el ESP32 está accesible
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.esp32EndpointStatus}');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
