import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/supabase/supabase_auth_service.dart';
import '../../data/models/user_model.dart';
import '../../config/supabase_config.dart';
import '../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  SupabaseAuthService? _authService;

  SupabaseAuthService get _service => _authService ??= SupabaseAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService?.isLoggedIn ?? false;

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.signIn(email: email, password: password);
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          _errorMessage = 'Debes confirmar tu correo antes de ingresar.';
          await _service.signOut();
          return false;
        }
        await _loadUserProfile(response.user!.id);
        _currentUser ??= _buildFallbackUserFromAuth(response.user!);
        return true;
      }
      _errorMessage = 'Credenciales incorrectas.';
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado. Intenta de nuevo.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required DateTime fechaNacimiento,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fullLastName = '$apellidoPaterno $apellidoMaterno'.trim();
      final response = await _service.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'apellido_paterno': apellidoPaterno,
          'apellido_materno': apellidoMaterno,
          'fecha_nacimiento': fechaNacimiento.toIso8601String(),
        },
      );

      if (response.user == null) {
        _errorMessage = 'No se pudo crear la cuenta. Intenta nuevamente.';
        return false;
      }

      await _upsertProfile(
        userId: response.user!.id,
        nombre: nombre,
        apellido: fullLastName,
        email: email,
      );

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Error inesperado al crear la cuenta.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final started = await _service.signInWithGoogle();
      if (!started) {
        _errorMessage = 'No se pudo iniciar sesión con Google.';
      }
      return started;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Error al iniciar sesión con Google.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleAuthSessionUpdate() async {
    final authUser = _service.currentUser;
    if (authUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    await _upsertProfile(
      userId: authUser.id,
      nombre: authUser.userMetadata?['nombre'] as String? ??
          authUser.userMetadata?['full_name'] as String? ??
          'Usuario',
      apellido: authUser.userMetadata?['apellido'] as String? ??
          authUser.userMetadata?['apellido_paterno'] as String? ??
          '',
      email: authUser.email ?? '',
    );
    await _loadUserProfile(authUser.id);
    _currentUser ??= _buildFallbackUserFromAuth(authUser);
    notifyListeners();
  }

  Future<bool> resendConfirmationEmail(String email) async {
    try {
      await _service.resendSignUpEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo reenviar el correo de confirmación.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = await _service.refreshUser();
      return user?.emailConfirmedAt != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _service.resetPassword(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _service.updatePassword(newPassword);
  }

  Future<void> _loadUserProfile(String userId) async {
    final data = await SupabaseConfig.client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      _currentUser = UserModel.fromJson(data);
    }
  }

  Future<void> _upsertProfile({
    required String userId,
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    await SupabaseConfig.client.from(AppConstants.tableProfiles).upsert({
      'id': userId,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'rol': 'usuario',
    });
  }

  UserModel _buildFallbackUserFromAuth(User user) {
    final nombre = user.userMetadata?['nombre'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        'Usuario';
    final apellido = user.userMetadata?['apellido'] as String? ??
        user.userMetadata?['apellido_paterno'] as String? ??
        '';
    return UserModel(
      id: user.id,
      nombre: nombre,
      apellido: apellido,
      email: user.email ?? '',
    );
  }

  void updateLocalUser(UserModel updated) {
    _currentUser = updated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
