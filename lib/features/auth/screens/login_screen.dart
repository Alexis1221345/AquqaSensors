import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../config/router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@aquasensors.mx');
  final _passwordController = TextEditingController(text: '1234');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
      auth.clearError();
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, AppRouter.register);
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Ingresa tu correo primero para recuperar la contraseña.');
      return;
    }
    context.read<AuthProvider>().resetPassword(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Revisa tu correo para restablecer tu contraseña.')),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.statusCritico),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header azul ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AquaSensors', style: AppTextStyles.headerTitle),
                    Text('CONTROL WATER QUALITY',
                        style: AppTextStyles.headerSubtitle),
                  ],
                ),
              ],
            ),
          ),

          // ── Formulario ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    AuthFormField(
                      label: 'CORREO ELECTRÓNICO',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AuthFormField(
                      label: 'CONTRASEÑA',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa tu contraseña';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón Iniciar Sesión
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: auth.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Iniciar Sesión'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón Crear Cuenta
                    OutlinedButton(
                      onPressed: _goToRegister,
                      child: const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 16),

                    // Olvidaste contraseña
                    Center(
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}