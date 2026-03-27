import '../../config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/pool_model.dart';
import '../supabase/supabase_storage_service.dart';
import 'dart:io';

class PoolRepository {
  final _client = SupabaseConfig.client;
  final _storage = SupabaseStorageService();

  Future<List<PoolModel>> getPoolsByOwner(String ownerId) async {
    final data = await _client
        .from(AppConstants.tablePools)
        .select()
        .eq('owner_id', ownerId)
        .order('creada_en', ascending: false);

    return (data as List)
        .map((e) => PoolModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PoolModel?> getPool(String poolId) async {
    final data = await _client
        .from(AppConstants.tablePools)
        .select()
        .eq('id', poolId)
        .maybeSingle();

    if (data == null) return null;
    return PoolModel.fromJson(data as Map<String, dynamic>);
  }

  Future<String> uploadImage({
    required String poolId,
    required File imageFile,
  }) =>
      _storage.uploadPoolImage(poolId: poolId, imageFile: imageFile);

  Future<List<String>> getImages(String poolId) =>
      _storage.getPoolImages(poolId);
}
