import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DevicePermissionHelper {
  DevicePermissionHelper._();

  static Future<bool> requestWifiAccess() async {
    if (!Platform.isAndroid) return true;

    final locationStatus = await Permission.locationWhenInUse.request();

    // En algunos equipos/SDK, nearbyWifiDevices puede no ser necesario
    // para leer SSID; se solicita como complemento sin bloquear el flujo.
    final wifiNearbyStatus = await Permission.nearbyWifiDevices.request();

    return _isGranted(locationStatus) || _isGranted(wifiNearbyStatus);
  }

  static Future<bool> requestBluetoothAccess() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final hasModernBluetooth =
        _isGranted(statuses[Permission.bluetoothScan]!) &&
        _isGranted(statuses[Permission.bluetoothConnect]!);
    final hasLegacyBluetooth = _isGranted(statuses[Permission.locationWhenInUse]!);

    return hasModernBluetooth || hasLegacyBluetooth;
  }

  static bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }
}

