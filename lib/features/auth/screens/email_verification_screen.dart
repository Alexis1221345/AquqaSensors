import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _checking = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    final verified = await context.read<AuthProvider>().checkEmailVerification();

    if (!mounted) return;
    setState(() => _checking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu correo aun no esta verificado.'),
          backgroundColor: AppColors.statusAlerta,
        ),
      );
      return;
    }

    await context.read<AuthProvider>().handleAuthSessionUpdate();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
  }

  Future<void> _resendEmail() async {
    final email = widget.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontro un correo para reenviar.'),
          backgroundColor: AppColors.statusCritico,
        ),
      );
      return;
    }

    final ok = await context.read<AuthProvider>().resendConfirmationEmail(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Correo de confirmacion reenviado.'
              : 'No se pudo reenviar el correo.',
        ),
        backgroundColor: ok ? AppColors.statusOptimo : AppColors.statusCritico,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 52, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('Confirma tu cuenta', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              widget.email == null
                  ? 'Te enviamos un enlace de confirmacion. Abre tu correo para activar la cuenta.'
                  : 'Te enviamos un enlace de confirmacion a ${widget.email}. Abre tu correo para activar la cuenta.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checking ? null : _checkVerification,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Ya confirme mi correo'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _resendEmail,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Reenviar correo de confirmacion'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (_) => false,
                );
              },
              child: const Text('Volver a inicio de sesion'),
            ),
          ],
        ),
      ),
    );
  }
}

