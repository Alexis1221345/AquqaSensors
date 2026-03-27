import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../core/constants/app_constants.dart';

class SupabaseStorageService {
  final _client = SupabaseConfig.client;

  // ── Avatar de usuario ─────────────────────────────────────────────────────

  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final ext = imageFile.path.split('.').last;
    final path = '$userId/avatar.$ext';

    await _client.storage
        .from(AppConstants.bucketAvatars)
        .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));

    return _client.storage
        .from(AppConstants.bucketAvatars)
        .getPublicUrl(path);
  }

  // ── Imágenes de alberca ───────────────────────────────────────────────────

  Future<String> uploadPoolImage({
    required String poolId,
    required File imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = imageFile.path.split('.').last;
    final path = '$poolId/$timestamp.$ext';

    await _client.storage
        .from(AppConstants.bucketImages)
        .upload(path, imageFile);

    return _client.storage
        .from(AppConstants.bucketImages)
        .getPublicUrl(path);
  }

  Future<List<String>> getPoolImages(String poolId) async {
    final files = await _client.storage
        .from(AppConstants.bucketImages)
        .list(path: poolId);

    return files.map((f) {
      return _client.storage
          .from(AppConstants.bucketImages)
          .getPublicUrl('$poolId/${f.name}');
    }).toList();
  }

  Future<void> deletePoolImage({
    required String poolId,
    required String fileName,
  }) async {
    await _client.storage
        .from(AppConstants.bucketImages)
        .remove(['$poolId/$fileName']);
  }
}
