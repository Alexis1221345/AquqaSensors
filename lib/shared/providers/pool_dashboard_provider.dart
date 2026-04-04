import 'package:flutter/material.dart';
import '../../data/models/pool_dashboard_model.dart';
import '../../data/supabase/supabase_pool_service.dart';

class PoolDashboardProvider extends ChangeNotifier {
  final _service = SupabasePoolService();

  PoolDashboardModel? _dashboard;
  bool _loading = false;
  String? _error;

  PoolDashboardModel? get dashboard => _dashboard;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboard(String poolId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard(poolId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _dashboard = null;
    _error = null;
    notifyListeners();
  }
}

