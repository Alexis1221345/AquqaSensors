import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/supabase/supabase_storage_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/profile_form_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _passwordActualCtrl = TextEditingController();
  final _passwordNuevoCtrl = TextEditingController();
  final _passwordConfirmarCtrl = TextEditingController();

  final _storageService = SupabaseStorageService();
  File? _newAvatarFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nombreCtrl.text = user.nombre;
      _apellidoCtrl.text = user.apellido;
      _emailCtrl.text = user.email;
      _telefonoCtrl.text = user.telefono ?? '';
      _empresaCtrl.text = user.empresa ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _empresaCtrl.dispose();
    _passwordActualCtrl.dispose();
    _passwordNuevoCtrl.dispose();
    _passwordConfirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    try {
      // Subir nueva foto si se seleccionó
      String? newAvatarUrl;
      if (_newAvatarFile != null) {
        newAvatarUrl = await _storageService.uploadAvatar(
          userId: user.id,
          imageFile: _newAvatarFile!,
        );
      }

      // Cambio de contraseña (solo si llenó los campos)
      if (_passwordNuevoCtrl.text.isNotEmpty) {
        if (_passwordNuevoCtrl.text != _passwordConfirmarCtrl.text) {
          _showError('Las contraseñas nuevas no coinciden.');
          return;
        }
        await auth.updatePassword(_passwordNuevoCtrl.text);
      }

      // Actualizar modelo local
      final updated = user.copyWith(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        empresa: _empresaCtrl.text.trim(),
        avatarUrl: newAvatarUrl ?? user.avatarUrl,
      );
      auth.updateLocalUser(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.statusCritico),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Editar Perfil',
        showBack: true,
        actions: const [MenuIconButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _newAvatarFile != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: FileImage(_newAvatarFile!),
                        )
                      : AvatarWidget(
                          initials: user?.initials ?? '??',
                          imageUrl: user?.avatarUrl,
                          size: 80,
                        ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Cambiar foto'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Datos personales ─────────────────────────────────────────────
            _sectionHeader('DATOS PERSONALES', Icons.person_outline),
            const SizedBox(height: 12),
            ProfileFormField(
                label: 'Nombre', controller: _nombreCtrl),
            const SizedBox(height: 12),
            ProfileFormField(
                label: 'Apellido', controller: _apellidoCtrl),
            const SizedBox(height: 12),
            ProfileFormField(
              label: 'Correo Electrónico',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            ProfileFormField(
              label: 'Teléfono',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            ProfileFormField(
                label: 'Empresa / Organización',
                controller: _empresaCtrl),
            const SizedBox(height: 12),
            ProfileFormField(
              label: 'Rol',
              controller: TextEditingController(
                  text: _capitalize(user?.rol ?? '—')),
              readOnly: true,
            ),
            const SizedBox(height: 20),

            // ── Cambiar contraseña ───────────────────────────────────────────
            _sectionHeader('CAMBIAR CONTRASEÑA', Icons.lock_outline),
            const SizedBox(height: 12),
            _PasswordField(
                label: 'Contraseña actual',
                controller: _passwordActualCtrl),
            const SizedBox(height: 12),
            _PasswordField(
                label: 'Nueva contraseña',
                controller: _passwordNuevoCtrl),
            const SizedBox(height: 12),
            _PasswordField(
                label: 'Confirmar contraseña',
                controller: _passwordConfirmarCtrl),
            const SizedBox(height: 24),

            // ── Guardar ──────────────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar cambios'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Campo de contraseña con toggle visibilidad ────────────────────────────────

class _PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _PasswordField({required this.label, required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
