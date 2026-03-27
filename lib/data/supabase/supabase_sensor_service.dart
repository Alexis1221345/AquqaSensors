import '../../config/supabase_config.dart';
import '../../core/constants/app_constants.dart';

class SupabaseSensorService {
  final _client = SupabaseConfig.client;

  // ── Últimas lecturas individuales ─────────────────────────────

  Future<double?> getLatestPh(String poolId) async {
    final data = await _client
        .from(AppConstants.tableReadingsPh)
        .select('valor')
        .eq('pool_id', poolId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? (data['valor'] as num).toDouble() : null;
  }

  Future<double?> getLatestCloro(String poolId) async {
    final data = await _client
        .from(AppConstants.tableReadingsCloro)
        .select('valor')
        .eq('pool_id', poolId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? (data['valor'] as num).toDouble() : null;
  }

  Future<double?> getLatestTemperatura(String poolId) async {
    final data = await _client
        .from(AppConstants.tableReadingsTemperatura)
        .select('valor')
        .eq('pool_id', poolId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? (data['valor'] as num).toDouble() : null;
  }

  Future<double?> getLatestTurbidez(String poolId) async {
    final data = await _client
        .from(AppConstants.tableReadingsTurbidez)
        .select('valor')
        .eq('pool_id', poolId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? (data['valor'] as num).toDouble() : null;
  }

  Future<double?> getLatestAlcalinidad(String poolId) async {
    final data = await _client
        .from(AppConstants.tableReadingsAlcalinidad)
        .select('valor')
        .eq('pool_id', poolId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? (data['valor'] as num).toDouble() : null;
  }

  // ── Historial normalizado para gráficas ───────────────────────

  Future<List<double>> getHistory({
    required String table,
    required String poolId,
    required DateTime from,
    required DateTime to,
    required double absMin,
    required double absMax,
  }) async {
    final data = await _client
        .from(table)
        .select('valor')
        .eq('pool_id', poolId)
        .gte('timestamp', from.toIso8601String())
        .lte('timestamp', to.toIso8601String())
        .order('timestamp');

    if ((data as List).isEmpty) return [];

    return data.map((e) {
      final v = (e['valor'] as num).toDouble();
      if (absMax == absMin) return 0.0;
      return ((v - absMin) / (absMax - absMin)).clamp(0.0, 1.0);
    }).toList();
  }

  // ── Insertar lecturas desde ESP32 ─────────────────────────────

  Future<void> insertPh(String poolId, double valor, String status) async {
    await _client.from(AppConstants.tableReadingsPh).insert({
      'pool_id': poolId, 'valor': valor,
      'status': status, 'source': 'esp32',
    });
  }

  Future<void> insertCloro(String poolId, double valor, String status) async {
    await _client.from(AppConstants.tableReadingsCloro).insert({
      'pool_id': poolId, 'valor': valor,
      'status': status, 'source': 'esp32',
    });
  }

  Future<void> insertTemperatura(String poolId, double valor, String status) async {
    await _client.from(AppConstants.tableReadingsTemperatura).insert({
      'pool_id': poolId, 'valor': valor,
      'status': status, 'source': 'esp32',
    });
  }

  Future<void> insertTurbidez(String poolId, double valor, String status) async {
    await _client.from(AppConstants.tableReadingsTurbidez).insert({
      'pool_id': poolId, 'valor': valor,
      'status': status, 'source': 'esp32',
    });
  }
}