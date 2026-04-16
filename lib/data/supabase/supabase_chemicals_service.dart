import '../../config/supabase_config.dart';
import '../models/pool_dashboard_model.dart';
import '../models/pool_chemical_model.dart';

class SupabaseChemicalsService {
  final _client = SupabaseConfig.client;

  Future<List<PoolChemicalModel>> getPoolChemicals(String poolId) async {
    final data = await _client
        .from('pool_chemicals')
        .select()
        .eq('pool_id', poolId)
        .eq('activo', true)
        .order('categoria');

    return (data as List)
        .map((e) => PoolChemicalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertChemical(PoolChemicalModel chemical) async {
    final payload = chemical.copyWith(activo: true).toJson()
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _client
        .from('pool_chemicals')
        .upsert(payload, onConflict: 'pool_id,categoria');
  }

  Future<void> deactivateChemical(String poolId, String categoria) async {
    await _client
        .from('pool_chemicals')
        .update({
          'activo': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('pool_id', poolId)
        .eq('categoria', categoria);
  }

  Future<List<ChemicalDoseHistoryModel>> getDoseHistory({
    required String poolId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final data = await _client
          .from('chemical_doses')
          .select()
          .eq('pool_id', poolId)
          .gte('timestamp', from.toIso8601String())
          .lte('timestamp', to.toIso8601String())
          .order('timestamp', ascending: true);
      return (data as List)
          .map((e) =>
              ChemicalDoseHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
