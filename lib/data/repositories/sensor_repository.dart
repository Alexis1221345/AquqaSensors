import '../../core/constants/app_constants.dart';
import '../../core/utils/sensor_status_helper.dart';
import '../../data/arduino/esp32_service.dart';
import '../../data/supabase/supabase_sensor_service.dart';

class SensorRepository {
  final SupabaseSensorService _supabase = SupabaseSensorService();
  final Esp32Service _esp32 = Esp32Service();

  Future<double?> getLatestPh(String poolId) =>
      _supabase.getLatestPh(poolId);

  Future<double?> getLatestCloro(String poolId) =>
      _supabase.getLatestCloro(poolId);

  Future<double?> getLatestTemperatura(String poolId) =>
      _supabase.getLatestTemperatura(poolId);

  Future<double?> getLatestTurbidez(String poolId) =>
      _supabase.getLatestTurbidez(poolId);

  Future<double?> getLatestAlcalinidad(String poolId) =>
      _supabase.getLatestAlcalinidad(poolId);

  Future<List<double>> getHistory({
    required String table,
    required String poolId,
    required DateTime from,
    required DateTime to,
    required double absMin,
    required double absMax,
  }) =>
      _supabase.getHistory(
        table: table,
        poolId: poolId,
        from: from,
        to: to,
        absMin: absMin,
        absMax: absMax,
      );

  Future<void> saveFromEsp32(String poolId) async {
    final reading = await _esp32.fetchReadings(poolId: poolId);
    if (reading == null) return;

    await Future.wait([
      _supabase.insertPh(
        poolId, reading.ph,
        SensorStatusHelper.phStatus(reading.ph).name,
      ),
      _supabase.insertCloro(
        poolId, reading.cloro,
        SensorStatusHelper.cloroStatus(reading.cloro).name,
      ),
      _supabase.insertTemperatura(
        poolId, reading.temperatura,
        SensorStatusHelper.temperaturaStatus(reading.temperatura).name,
      ),
      _supabase.insertTurbidez(
        poolId, reading.turbidez,
        SensorStatusHelper.turbidezStatus(reading.turbidez).name,
      ),
    ]);
  }
}