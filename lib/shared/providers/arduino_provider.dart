import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/arduino/esp32_service.dart';
import '../../data/arduino/esp32_wifi_service.dart';
import '../../data/arduino/esp32_bluetooth_service.dart';

enum Esp32Transport { none, wifi, bluetooth }

/// Indica el estado de proximidad detectado basado en RSSI.
enum ProximityState { unknown, veryFar, far, near, veryNear }

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
  int? _lastBleDeviceRssi;
  bool _autoSwitchBluetooth = true;
  bool _autoConnectByProximity = false; // Nueva: auto-conexión por proximidad
  Timer? _autoSwitchTimer;
  Timer? _proximityCheckTimer;
  String? _errorMessage;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get currentIp => _currentIp;
  Esp32Transport get activeTransport => _activeTransport;
  List<BleDeviceCandidate> get bleDevices => _bleDevices;
  bool get autoSwitchBluetooth => _autoSwitchBluetooth;
  bool get autoConnectByProximity => _autoConnectByProximity;
  String? get connectedBleDeviceName => _connectedBleDeviceName;
  int? get lastBleDeviceRssi => _lastBleDeviceRssi;
  bool get hasBluetoothSetup => _lastBleDeviceId != null;
  String? get errorMessage => _errorMessage;

  /// Retorna el estado de proximidad actual basado en RSSI.
  ProximityState get proximityState {
    if (_lastBleDeviceRssi == null) return ProximityState.unknown;
    if (_lastBleDeviceRssi! > -50) return ProximityState.veryNear;
    if (_lastBleDeviceRssi! > -65) return ProximityState.near;
    if (_lastBleDeviceRssi! > -75) return ProximityState.far;
    return ProximityState.veryFar;
  }

  /// Retorna un indicador visual de la fortaleza de señal (0-4 barras).
  int get signalStrength {
    if (_lastBleDeviceRssi == null) return 0;
    final rssi = _lastBleDeviceRssi!;
    if (rssi > -50) return 4;
    if (rssi > -65) return 3;
    if (rssi > -75) return 2;
    if (rssi > -85) return 1;
    return 0;
  }

  /// Retorna descripción de proximidad para UI.
  String get proximityDescription {
    switch (proximityState) {
      case ProximityState.veryNear:
        return 'Muy cerca (RSSI: $_lastBleDeviceRssi dBm)';
      case ProximityState.near:
        return 'Cerca (RSSI: $_lastBleDeviceRssi dBm)';
      case ProximityState.far:
        return 'Lejano (RSSI: $_lastBleDeviceRssi dBm)';
      case ProximityState.veryFar:
        return 'Muy lejano (RSSI: $_lastBleDeviceRssi dBm)';
      case ProximityState.unknown:
        return 'Proximidad desconocida';
    }
  }

  String get connectionDetail {
    if (!_isConnected) return 'Sin conexion activa';
    if (_activeTransport == Esp32Transport.bluetooth) {
      return _connectedBleDeviceName == null
          ? 'Bluetooth activo'
          : 'Bluetooth: $_connectedBleDeviceName (${proximityDescription})';
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

  Future<String?> getCurrentWifiIp() => _wifiService.getCurrentIp();

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

  /// Auto-configura el ESP32 con el WiFi actual cuando está cerca (proximidad detectada).
  Future<bool> autoProvisionWithCurrentNetwork({
    required String esp32Ip,
    required String password,
  }) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    final ok = await _wifiService.autoProvisionWithCurrentNetwork(
      esp32Ip: esp32Ip,
      password: password,
    );

    _isConnecting = false;
    if (!ok) {
      _errorMessage = 'No se pudo auto-configurar el WiFi en el ESP32.';
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
      _lastBleDeviceRssi = device.rssi;
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

  /// Habilita/deshabilita la auto-conexión automática cuando el dispositivo está cerca.
  void setAutoConnectByProximity(bool enabled) {
    _autoConnectByProximity = enabled;
    if (enabled && _lastBleDeviceId != null) {
      _startProximityCheckLoop();
    } else {
      _proximityCheckTimer?.cancel();
      _proximityCheckTimer = null;
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

  /// Inicia el loop de verificación de proximidad para auto-conexión.
  void _startProximityCheckLoop() {
    if (!_autoConnectByProximity || _lastBleDeviceId == null) return;
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkProximityAndConnect(),
    );
  }

  /// Verifica la proximidad del dispositivo y se conecta automáticamente si está cerca.
  Future<void> _checkProximityAndConnect() async {
    if (!_autoConnectByProximity || _lastBleDeviceId == null || _isConnecting) {
      return;
    }

    try {
      final nearby = await _bluetoothService.scanForEsp32(
        timeout: const Duration(seconds: 3),
      );
      
      final target = nearby.where((d) => d.id == _lastBleDeviceId).toList();
      if (target.isEmpty) return;

      final device = target.first;
      _lastBleDeviceRssi = device.rssi;

      // Si está muy cerca (RSSI > -65) e no está conectado, conectar automáticamente.
      if (!_isConnected && (device.rssi ?? -99) > -65) {
        await connectBluetooth(device);
      }

      notifyListeners();
    } catch (_) {
      // Ignorar errores de escaneo
    }
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

    // Actualizar RSSI incluso si ya estamos conectados
    _lastBleDeviceRssi = target.first.rssi;
    notifyListeners();

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
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = null;
    _bluetoothService.disconnect();
    _isConnected = false;
    _currentIp = '';
    _activeTransport = Esp32Transport.none;
    _connectedBleDeviceName = null;
    _lastBleDeviceRssi = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSwitchTimer?.cancel();
    _proximityCheckTimer?.cancel();
    _bluetoothService.disconnect();
    super.dispose();
  }
}
