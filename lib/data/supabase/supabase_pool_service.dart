import '../../config/supabase_config.dart';
import '../models/pool_dashboard_model.dart';

class SupabasePoolService {
  final _client = SupabaseConfig.client;

  /// Llama a get_pool_dashboard() y devuelve null si no hay datos o falla.
  Future<PoolDashboardModel?> getDashboard(String poolId) async {
    try {
      final response = await _client.rpc(
        'get_pool_dashboard',
        params: {'p_pool_id': poolId},
      );
      if (response == null) return null;
      return PoolDashboardModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

