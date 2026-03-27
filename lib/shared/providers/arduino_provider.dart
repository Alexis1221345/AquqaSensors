import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/arduino/esp32_service.dart';
import '../../data/arduino/esp32_wifi_service.dart';
import '../../data/arduino/esp32_bluetooth_service.dart';

enum Esp32Transport { none, wifi, bluetooth }

class ArduinoProvider extends ChangeNotifier {
  final Esp32Service _service = Esp32Service();
  final Esp32WifiService _wifiService = Esp32WifiService();
  final Esp32BluetoothService _bluetoothService = Esp32BluetoothService();

  bool _isConnected = false;
  bool _isConnecting = false;
  String _currentIp = '';
  Esp32Transport _activeTransport = Esp32Transport.none;
  List<BleDeviceCandidate> _bleDevices = const [];
  String? _connectedBleDeviceName;
  String? _lastBleDeviceId;
  bool _autoSwitchBluetooth = true;
  Timer? _autoSwitchTimer;
  String? _errorMessage;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get currentIp => _currentIp;
  Esp32Transport get activeTransport => _activeTransport;
  List<BleDeviceCandidate> get bleDevices => _bleDevices;
  bool get autoSwitchBluetooth => _autoSwitchBluetooth;
  String? get connectedBleDeviceName => _connectedBleDeviceName;
  bool get hasBluetoothSetup => _lastBleDeviceId != null;
  String? get errorMessage => _errorMessage;

  String get connectionDetail {
    if (!_isConnected) return 'Sin conexion activa';
    if (_activeTransport == Esp32Transport.bluetooth) {
      return _connectedBleDeviceName == null
          ? 'Bluetooth activo'
          : 'Bluetooth: $_connectedBleDeviceName';
    }
    return _currentIp.isNotEmpty ? 'Wi-Fi IP: $_currentIp' : 'Wi-Fi activo';
  }

  Future<bool> connect(String ip) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    _service.updateIp(ip);
    final result = await _service.checkConnection();

    _isConnected = result;
    _isConnecting = false;
    _currentIp = result ? ip : '';
    if (result) {
      _activeTransport = Esp32Transport.wifi;
      _startAutoSwitchLoop();
    }
    if (!result) _errorMessage = 'No se pudo conectar a $ip';

    notifyListeners();
    return result;
  }

  Future<String?> getCurrentWifiSsid() => _wifiService.getCurrentSsid();

  Future<bool> provisionEsp32Wifi({
    required String esp32Ip,
    required String ssid,
    required String password,
  }) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    final ok = await _wifiService.provisionWifiCredentials(
      esp32Ip: esp32Ip,
      ssid: ssid,
      password: password,
    );

    _isConnecting = false;
    if (!ok) {
      _errorMessage = 'No se pudo enviar la configuracion Wi-Fi al ESP32.';
    }
    notifyListeners();
    return ok;
  }

  Future<List<BleDeviceCandidate>> scanBluetoothDevices() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bleDevices = await _bluetoothService.scanForEsp32();
      return _bleDevices;
    } catch (_) {
      _errorMessage = 'No se pudieron obtener dispositivos Bluetooth.';
      return const [];
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> connectBluetooth(BleDeviceCandidate device) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    final ok = await _bluetoothService.connectToDevice(device.id);
    _isConnecting = false;

    if (ok) {
      _isConnected = true;
      _activeTransport = Esp32Transport.bluetooth;
      _connectedBleDeviceName = device.name;
      _lastBleDeviceId = device.id;
      _startAutoSwitchLoop();
    } else {
      _errorMessage = 'No se pudo conectar por Bluetooth a ${device.name}.';
    }

    notifyListeners();
    return ok;
  }

  void setAutoBluetoothSwitch(bool enabled) {
    _autoSwitchBluetooth = enabled;
    if (enabled) {
      _startAutoSwitchLoop();
    } else {
      _autoSwitchTimer?.cancel();
      _autoSwitchTimer = null;
    }
    notifyListeners();
  }

  void _startAutoSwitchLoop() {
    if (!_autoSwitchBluetooth) return;
    _autoSwitchTimer?.cancel();
    _autoSwitchTimer = Timer.periodic(
      const Duration(seconds: 18),
      (_) => _tryAutoSwitchBluetooth(),
    );
  }

  Future<void> _tryAutoSwitchBluetooth() async {
    if (!_autoSwitchBluetooth || _lastBleDeviceId == null || _isConnecting) {
      return;
    }

    final nearby = await _bluetoothService.scanForEsp32(
      timeout: const Duration(seconds: 3),
    );
    final target = nearby.where((d) => d.id == _lastBleDeviceId).toList();

    if (target.isEmpty) {
      if (_activeTransport == Esp32Transport.bluetooth && _currentIp.isNotEmpty) {
        _activeTransport = Esp32Transport.wifi;
        notifyListeners();
      }
      return;
    }

    if (_activeTransport == Esp32Transport.bluetooth) return;
    final ok = await _bluetoothService.connectToDevice(target.first.id);
    if (!ok) return;

    _activeTransport = Esp32Transport.bluetooth;
    _connectedBleDeviceName = target.first.name;
    _isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    _autoSwitchTimer?.cancel();
    _autoSwitchTimer = null;
    _bluetoothService.disconnect();
    _isConnected = false;
    _currentIp = '';
    _activeTransport = Esp32Transport.none;
    _connectedBleDeviceName = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSwitchTimer?.cancel();
    _bluetoothService.disconnect();
    super.dispose();
  }
}
