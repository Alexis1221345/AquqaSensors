import '../supabase/supabase_auth_service.dart';

class AuthRepository {
  final SupabaseAuthService _service = SupabaseAuthService();

  bool get isLoggedIn => _service.isLoggedIn;

  Future<bool> signIn(String email, String password) async {
    final res = await _service.signIn(email: email, password: password);
    return res.user != null;
  }

  Future<void> signOut() => _service.signOut();

  Future<void> resetPassword(String email) =>
      _service.resetPassword(email);

  Future<void> updatePassword(String newPassword) =>
      _service.updatePassword(newPassword);
}
