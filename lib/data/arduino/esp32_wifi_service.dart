import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

import '../../core/constants/app_constants.dart';

class Esp32WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Obtiene el SSID de la red actual del telefono (si el SO lo permite).
  Future<String?> getCurrentSsid() async {
    final rawSsid = await _networkInfo.getWifiName();
    if (rawSsid == null || rawSsid.isEmpty) return null;
    return rawSsid.replaceAll('"', '').trim();
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
}
