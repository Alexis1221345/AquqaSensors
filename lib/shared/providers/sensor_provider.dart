import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/sensor_status_helper.dart';
import '../../data/supabase/supabase_sensor_service.dart';
import '../../data/arduino/esp32_service.dart';
import '../../services/realtime_service.dart';

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
  List<double> alcalinidadHistory = [];

  final List<Map<String, dynamic>> _realtimeAlerts = [];
  final List<Map<String, dynamic>> _inventarioBajo = [];

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isLoading = false;
  String? _errorMessage;

  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  List<Map<String, dynamic>> get realtimeAlerts => _realtimeAlerts;
  List<Map<String, dynamic>> get inventarioBajo => _inventarioBajo;
  bool get hasRealtimeAlerts => _realtimeAlerts.isNotEmpty;

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
        _supabase.getHistory(
          table: AppConstants.tableReadingsAlcalinidad, poolId: poolId,
          from: from, to: to,
          absMin: AppConstants.alcalinidadAbsMin, absMax: AppConstants.alcalinidadAbsMax,
        ),
      ]);

      phHistory    = results[0];
      cloroHistory = results[1];
      tempHistory  = results[2];
      turbHistory  = results[3];
      alcalinidadHistory = results[4];

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

  void startRealtime(String poolId, String poolNombre) {
    _realtimeAlerts.clear();
    _inventarioBajo.clear();

    RealtimeService.instance.subscribeToPool(
      poolId: poolId,
      poolNombre: poolNombre,
      onNewReading: (parametro, valor, status) {
        switch (parametro) {
          case 'ph':
            ph = valor;
            phHistory = _appendHistory(phHistory, valor);
            break;
          case 'cloro':
            cloro = valor;
            cloroHistory = _appendHistory(cloroHistory, valor);
            break;
          case 'temperatura':
            temperatura = valor;
            tempHistory = _appendHistory(tempHistory, valor);
            break;
          case 'turbidez':
            turbidez = valor;
            turbHistory = _appendHistory(turbHistory, valor);
            break;
          case 'alcalinidad':
            alcalinidad = valor;
            alcalinidadHistory = _appendHistory(alcalinidadHistory, valor);
            break;
        }
        notifyListeners();
      },
      onNewAlert: (parametro, nivel, mensaje, valor) {
        _realtimeAlerts.insert(0, {
          'poolId': poolId,
          'poolNombre': poolNombre,
          'parametro': parametro,
          'nivel': nivel,
          'mensaje': mensaje,
          'valor': valor,
          'timestamp': DateTime.now(),
        });
        if (_realtimeAlerts.length > 20) {
          _realtimeAlerts.removeLast();
        }
        notifyListeners();
      },
      onInventarioBajo: (quimicoNombre, pct) {
        _inventarioBajo.insert(0, {
          'poolId': poolId,
          'poolNombre': poolNombre,
          'quimicoNombre': quimicoNombre,
          'pct': pct,
          'timestamp': DateTime.now(),
        });
        if (_inventarioBajo.length > 20) {
          _inventarioBajo.removeLast();
        }
        notifyListeners();
      },
    );
  }

  void stopRealtime() {
    RealtimeService.instance.unsubscribeAll();
  }

  void disconnect() {
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<double> _appendHistory(List<double> history, double value) {
    final next = List<double>.from(history)..add(value);
    if (next.length > 12) {
      return next.sublist(next.length - 12);
    }
    return next;
  }
}