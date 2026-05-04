import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';

class Esp32WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();
  
  // Configuración de detección de proximidad
  static const int RSSI_STRONG_THRESHOLD = -50;   // Muy cerca (< -50 dBm)
  static const int RSSI_GOOD_THRESHOLD = -65;     // Cerca
  static const int RSSI_WEAK_THRESHOLD = -75;     // Lejano

  /// Obtiene el SSID de la red actual del telefono (si el SO lo permite).
  Future<String?> getCurrentSsid() async {
    final rawSsid = await _networkInfo.getWifiName();
    if (rawSsid == null || rawSsid.isEmpty) return null;
    return rawSsid.replaceAll('"', '').trim();
  }

  /// Obtiene la dirección IP del dispositivo en la red WiFi.
  Future<String?> getCurrentIp() async {
    return await _networkInfo.getWifiIP();
  }

  /// Obtiene el BSSID (dirección MAC del router) actual.
  Future<String?> getCurrentBssid() async {
    return await _networkInfo.getWifiBSSID();
  }

  /// Verifica y solicita permisos necesarios para acceder a información de WiFi.
  Future<bool> requestWifiPermissions() async {
    final locationStatus = await Permission.location.request();
    final wifiStatus = await Permission.nearbyWifiDevices.request();
    
    return locationStatus.isGranted || locationStatus.isDenied;
  }

  /// Obtiene la fortaleza de la señal WiFi actual en dBm (RSSI).
  /// Nota: En iOS, esta información puede no estar disponible por restricciones del SO.
  Future<int?> getCurrentWifiRssi() async {
    try {
      // Para Android, network_info_plus tiene limitaciones con RSSI directamente.
      // Se recomienda usar connectivityplus o wifi_iot para Android.
      // Por ahora, retornamos null; se mejorará en futuras versiones.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Determina la proximidad basada en la fortaleza de señal.
  /// Retorna: 'strong' (muy cerca), 'good' (cerca), 'weak' (lejano), o 'unknown'.
  String evaluateProximity(int? rssi) {
    if (rssi == null) return 'unknown';
    if (rssi > RSSI_STRONG_THRESHOLD) return 'strong';
    if (rssi > RSSI_GOOD_THRESHOLD) return 'good';
    if (rssi > RSSI_WEAK_THRESHOLD) return 'weak';
    return 'very_weak';
  }

  /// Envia credenciales de Wi-Fi al ESP32 para que se una a la red local.
  Future<bool> provisionWifiCredentials({
    required String esp32Ip,
    required String ssid,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        'http://$esp32Ip:${AppConstants.esp32Port}${AppConstants.esp32EndpointProvisionWifi}',
      );

      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ssid': ssid,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Intenta auto-configurar el ESP32 con las credenciales del WiFi actual.
  /// Útil cuando el usuario está cerca del ESP32 y queremos facilitar la conexión.
  Future<bool> autoProvisionWithCurrentNetwork({
    required String esp32Ip,
    required String password,
  }) async {
    try {
      final ssid = await getCurrentSsid();
      if (ssid == null || ssid.isEmpty) return false;

      return await provisionWifiCredentials(
        esp32Ip: esp32Ip,
        ssid: ssid,
        password: password,
      );
    } catch (_) {
      return false;
    }
  }
}
