import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/pool_model.dart';

class PoolProvider extends ChangeNotifier {
  List<PoolModel> _pools = [];
  PoolModel? _activePool;
  bool _loading = false;

  List<PoolModel> get pools => _pools;
  PoolModel? get activePool => _activePool;
  String? get activePoolId => _activePool?.id;
  bool get loading => _loading;
  bool get hasPools => _pools.isNotEmpty;

  /// Carga todas las albercas del usuario ordenadas por mas reciente.
  /// Si no hay alberca activa seleccionada, activa la primera (mas reciente).
  Future<void> loadPools(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(AppConstants.tablePools)
          .select()
          .eq('owner_id', userId)
          .order('creada_en', ascending: false);

      _pools = (data as List)
          .map((e) => PoolModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Mantiene la activa si sigue existiendo; si no, activa la primera.
      if (_pools.isNotEmpty) {
        final stillExists = _pools.any((p) => p.id == _activePool?.id);
        if (!stillExists) _activePool = _pools.first;
      } else {
        _activePool = null;
      }
    } catch (_) {
      _pools = [];
      _activePool = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cambia la alberca activa y notifica a todas las pantallas.
  void setActivePool(PoolModel pool) {
    _activePool = pool;
    notifyListeners();
  }

  /// Limpia todo al cerrar sesion.
  void clear() {
    _pools = [];
    _activePool = null;
    notifyListeners();
  }
}

