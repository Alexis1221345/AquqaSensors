import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _fechaNacimiento;

  @override
  void dispose() {
    _emailController.dispose();
    _nombreController.dispose();
    _apellidoMaternoController.dispose();
    _apellidoPaternoController.dispose();
    _fechaNacimientoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('es', 'MX'),
    );

    if (picked == null) return;
    setState(() {
      _fechaNacimiento = picked;
      _fechaNacimientoController.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      _showError('Selecciona tu fecha de nacimiento.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombre: _nombreController.text.trim(),
      apellidoPaterno: _apellidoPaternoController.text.trim(),
      apellidoMaterno: _apellidoMaternoController.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.verifyEmail,
        arguments: _emailController.text.trim(),
      );
      return;
    }

    if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
      auth.clearError();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final started = await auth.signInWithGoogle();

    if (!mounted) return;
    if (!started) {
      if (auth.errorMessage != null) {
        _showError(auth.errorMessage!);
        auth.clearError();
      }
      return;
    }

    await auth.handleAuthSessionUpdate();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.home);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.statusCritico),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registro de usuario', style: AppTextStyles.heading2),
              const SizedBox(height: 4),
              const Text(
                'Completa tus datos para crear tu cuenta AquaSensors.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              AuthFormField(
                label: 'NOMBRE',
                controller: _nombreController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: 'APELLIDO MATERNO',
                controller: _apellidoMaternoController,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa tu apellido materno'
                    : null,
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: 'APELLIDO PATERNO',
                controller: _apellidoPaternoController,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa tu apellido paterno'
                    : null,
              ),
              const SizedBox(height: 14),
              Text('FECHA DE NACIMIENTO', style: AppTextStyles.labelField),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fechaNacimientoController,
                readOnly: true,
                onTap: _pickBirthDate,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Selecciona tu fecha de nacimiento';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: 'CORREO ELECTRONICO',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                  if (!v.contains('@')) return 'Correo no valido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: 'CONTRASENA',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa una contrasena';
                  if (v.length < 6) return 'Minimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: 'CONFIRMAR CONTRASENA',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma tu contrasena';
                  if (v != _passwordController.text) {
                    return 'Las contrasenas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear cuenta'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: Image.asset(
                  'assets/Inicio_Sesion/google_logo.png',
                  width: 18,
                  height: 18,
                ),
                label: const Text('Iniciar sesion con Google'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ya tengo cuenta, iniciar sesion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

