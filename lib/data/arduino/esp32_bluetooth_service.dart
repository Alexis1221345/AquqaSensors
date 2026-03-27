import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/app_constants.dart';

class BleDeviceCandidate {
  final String id;
  final String name;
  final int? rssi;

  const BleDeviceCandidate({
    required this.id,
    required this.name,
    this.rssi,
  });
}

class Esp32BluetoothService {
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<List<BleDeviceCandidate>> scanForEsp32({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) return const [];

    await FlutterBluePlus.startScan(timeout: timeout);
    final scanResults = await FlutterBluePlus.scanResults
        .map((items) => List<ScanResult>.from(items))
        .first;
    await FlutterBluePlus.stopScan();

    final filtered = <String, BleDeviceCandidate>{};
    for (final result in scanResults) {
      final adv = result.advertisementData;
      final name = adv.advName.isNotEmpty
          ? adv.advName
          : (result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Dispositivo BLE');

      final hasEsp32Name = name.toLowerCase().contains('esp32');
      final hasService = adv.serviceUuids
          .map((uuid) => uuid.toString().toLowerCase())
          .contains(AppConstants.esp32BleServiceUuid);

      if (!hasEsp32Name && !hasService) continue;

      final id = result.device.remoteId.str;
      filtered[id] = BleDeviceCandidate(id: id, name: name, rssi: result.rssi);
    }

    return filtered.values.toList()
      ..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
  }

  Future<bool> connectToDevice(String deviceId) async {
    try {
      final scan = await scanForEsp32(timeout: const Duration(seconds: 4));
      if (scan.every((item) => item.id != deviceId)) return false;
      final device = BluetoothDevice.fromId(deviceId);

      await device.connect(timeout: const Duration(seconds: 8));
      _connectedDevice = device;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } finally {
      _connectedDevice = null;
    }
  }
}
