import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/sensor_status_helper.dart';
import '../../data/supabase/supabase_sensor_service.dart';
import '../../data/arduino/esp32_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SensorProvider extends ChangeNotifier {
  final SupabaseSensorService _supabase = SupabaseSensorService();
  final Esp32Service _esp32 = Esp32Service();

  // Valores actuales — null = sin datos todavía
  double? ph;
  double? cloro;
  double? temperatura;
  double? turbidez;
  double? alcalinidad;

  // Historial normalizado para gráficas
  List<double> phHistory = [];
  List<double> cloroHistory = [];
  List<double> tempHistory = [];
  List<double> turbHistory = [];

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isLoading = false;
  String? _errorMessage;

  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;

  // ── Carga las últimas lecturas de Supabase ────────────────────

  Future<void> loadLatestReadings(String poolId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ejecuta todas las consultas en paralelo
      final results = await Future.wait([
        _supabase.getLatestPh(poolId),
        _supabase.getLatestCloro(poolId),
        _supabase.getLatestTemperatura(poolId),
        _supabase.getLatestTurbidez(poolId),
        _supabase.getLatestAlcalinidad(poolId),
      ]);

      ph           = results[0];
      cloro        = results[1];
      temperatura  = results[2];
      turbidez     = results[3];
      alcalinidad  = results[4];

    } catch (e) {
      _errorMessage = 'Error al cargar lecturas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Carga historial para gráficas ─────────────────────────────

  Future<void> loadHistoricalReadings({
    required String poolId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final results = await Future.wait([
        _supabase.getHistory(
          table: AppConstants.tableReadingsPh, poolId: poolId,
          from: from, to: to,
          absMin: AppConstants.phAbsMin, absMax: AppConstants.phAbsMax,
        ),
        _supabase.getHistory(
          table: AppConstants.tableReadingsCloro, poolId: poolId,
          from: from, to: to,
          absMin: AppConstants.cloroAbsMin, absMax: AppConstants.cloroAbsMax,
        ),
        _supabase.getHistory(
          table: AppConstants.tableReadingsTemperatura, poolId: poolId,
          from: from, to: to,
          absMin: AppConstants.tempAbsMin, absMax: AppConstants.tempAbsMax,
        ),
        _supabase.getHistory(
          table: AppConstants.tableReadingsTurbidez, poolId: poolId,
          from: from, to: to,
          absMin: AppConstants.turbidezMin, absMax: AppConstants.turbidezAbsMax,
        ),
      ]);

      phHistory    = results[0];
      cloroHistory = results[1];
      tempHistory  = results[2];
      turbHistory  = results[3];

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar historial: $e';
      notifyListeners();
    }
  }

  // ── Conexión ESP32 ────────────────────────────────────────────

  Future<void> connectToEsp32({required String poolId, String? ip}) async {
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    if (ip != null) _esp32.updateIp(ip);

    final connected = await _esp32.checkConnection();
    if (!connected) {
      _connectionStatus = ConnectionStatus.error;
      _errorMessage = 'No se pudo conectar al ESP32. Verifica la IP y red WiFi.';
      notifyListeners();
      return;
    }

    _connectionStatus = ConnectionStatus.connected;

    final reading = await _esp32.fetchReadings(poolId: poolId);
    if (reading != null) {
      ph          = reading.ph;
      cloro       = reading.cloro;
      temperatura = reading.temperatura;
      turbidez    = reading.turbidez;

      // Guardar en Supabase
      await Future.wait([
        _supabase.insertPh(poolId, reading.ph,
            SensorStatusHelper.phStatus(reading.ph).name),
        _supabase.insertCloro(poolId, reading.cloro,
            SensorStatusHelper.cloroStatus(reading.cloro).name),
        _supabase.insertTemperatura(poolId, reading.temperatura,
            SensorStatusHelper.temperaturaStatus(reading.temperatura).name),
        _supabase.insertTurbidez(poolId, reading.turbidez,
            SensorStatusHelper.turbidezStatus(reading.turbidez).name),
      ]);
    }

    notifyListeners();
  }

  void disconnect() {
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}