import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../config/router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/pool/screens/add_pool_sheet.dart';

class AppDrawer extends StatelessWidget {
  final Future<void> Function()? onConnectWifi;
  final Future<void> Function()? onConnectBluetooth;

  const AppDrawer({
    super.key,
    this.onConnectWifi,
    this.onConnectBluetooth,
  });

  void _handleDrawerAction(
    BuildContext context,
    Future<void> Function()? action,
  ) {
    Navigator.pop(context);
    if (action == null) return;

    Future<void>.delayed(
      const Duration(milliseconds: 220),
      () => action(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final initials = user?.initials ?? '??';
    final nombre = user?.nombreCompleto ?? 'Usuario';
    final email = user?.email ?? '';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Cabecera con iniciales ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              color: AppColors.primary,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 1. Perfil ───────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.account);
              },
            ),

            // ── 2. Agregar Alberca ──────────────────────────────────────────
            _DrawerItem(
              icon: Icons.pool_outlined,
              label: 'Agregar Alberca',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const AddPoolSheet(),
                );
              },
            ),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.settings_input_component_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                title: const Text(
                  'Conectar dispositivo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Wi‑Fi o Bluetooth',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
                children: [
                  _DrawerItem(
                    icon: Icons.wifi,
                    label: 'Conectar vía Wi‑Fi',
                    enabled: onConnectWifi != null,
                    onTap: () =>
                        _handleDrawerAction(context, onConnectWifi),
                  ),
                  _DrawerItem(
                    icon: Icons.bluetooth,
                    label: 'Conectar vía Bluetooth',
                    enabled: onConnectBluetooth != null,
                    onTap: () =>
                        _handleDrawerAction(context, onConnectBluetooth),
                  ),
                ],
              ),
            ),

            const Spacer(),

            const Divider(height: 1, color: AppColors.border),

            // ── 3. Cerrar sesión ────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: AppColors.statusCritico,
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRouter.login);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool enabled;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.textPrimary;
    final itemColor = enabled ? baseColor : AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      onTap: enabled ? onTap : null,
      horizontalTitleGap: 8,
    );
  }
}
