import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../config/router.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/profile_info_row.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header azul con avatar y botón volver ─────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 24,
            ),
            child: Column(
              children: [
                // Botón volver
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                AvatarWidget(
                  initials: user?.initials ?? '??',
                  imageUrl: user?.avatarUrl,
                  size: 80,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.nombreCompleto ?? 'Usuario',
                  style: AppTextStyles.headerTitle,
                ),
                Text(
                  _capitalize(user?.rol ?? 'usuario'),
                  style: AppTextStyles.headerSubtitle,
                ),
              ],
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Datos personales
                _SectionCard(
                  title: 'DATOS PERSONALES',
                  children: [
                    ProfileInfoRow(
                        label: 'Nombre',
                        value: user?.nombreCompleto ?? '—'),
                    const Divider(height: 1, color: AppColors.border),
                    ProfileInfoRow(
                        label: 'Correo', value: user?.email ?? '—'),
                    const Divider(height: 1, color: AppColors.border),
                    ProfileInfoRow(
                        label: 'Teléfono',
                        value: user?.telefono ?? '—'),
                    const Divider(height: 1, color: AppColors.border),
                    ProfileInfoRow(
                        label: 'Rol',
                        value: _capitalize(user?.rol ?? '—')),
                  ],
                ),
                const SizedBox(height: 12),

                // Información de cuenta
                _SectionCard(
                  title: 'INFORMACIÓN DE LA CUENTA',
                  children: [
                    ProfileInfoRow(
                      label: 'Miembro desde',
                      value: user?.miembroDesde != null
                          ? _monthYear(user!.miembroDesde!)
                          : '—',
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ProfileInfoRow(
                      label: 'Última sesión',
                      value: user?.ultimaSesion != null
                          ? _lastSessionLabel(user!.ultimaSesion!)
                          : 'Hoy',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón editar perfil
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.editProfile),
                  icon: const Text('✏️'),
                  label: const Text('Editar Perfil'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _monthYear(DateTime d) {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[d.month]} ${d.year}';
  }

  String _lastSessionLabel(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return DateFormatter.toDisplay(d);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
