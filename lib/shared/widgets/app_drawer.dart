import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../config/router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/pool_dashboard_provider.dart';
import '../../shared/providers/pool_provider.dart';
import '../../data/models/pool_model.dart';
import '../../features/pool/screens/add_pool_sheet.dart';

class AppDrawer extends StatefulWidget {
  final Future<void> Function()? onConnectWifi;
  final Future<void> Function()? onConnectBluetooth;
  final Future<void> Function(String poolId)? onPoolChanged;

  const AppDrawer({
    super.key,
    this.onConnectWifi,
    this.onConnectBluetooth,
    this.onPoolChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

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

  void _openAddPoolSheet(BuildContext context) {
    Navigator.pop(context);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AddPoolSheet(
          onSaved: () async {
            final userId = context.read<AuthProvider>().currentUser?.id;
            if (userId == null) return;
            final poolProvider = context.read<PoolProvider>();
            await poolProvider.loadPools(userId);
            if (poolProvider.pools.isNotEmpty) {
              poolProvider.setActivePool(poolProvider.pools.first);
            }
            final newPool = poolProvider.activePool;
            if (newPool != null && widget.onPoolChanged != null) {
              await widget.onPoolChanged!(newPool.id);
            }
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final poolProv = context.watch<PoolProvider>();
    final initials = user?.initials ?? '??';
    final nombre = user?.nombreCompleto ?? 'Usuario';
    final email = user?.email ?? '';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Cabecera
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

            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.account);
              },
            ),

            // Mis Albercas
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.pool_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                title: const Text(
                  'Mis Albercas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  poolProv.activePool?.nombre ?? 'Sin alberca seleccionada',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.statusOptimo,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                childrenPadding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                children: [
                  if (poolProv.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (poolProv.pools.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tienes albercas registradas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...poolProv.pools.map(
                      (pool) => _PoolItem(
                        pool: pool,
                        isActive: pool.id == poolProv.activePoolId,
                        onTap: () async {
                          poolProv.setActivePool(pool);
                          Navigator.pop(context);
                          if (widget.onPoolChanged != null) {
                            await widget.onPoolChanged!(pool.id);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _openAddPoolSheet(context),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Nueva alberca',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                    enabled: widget.onConnectWifi != null,
                    onTap: () =>
                        _handleDrawerAction(context, widget.onConnectWifi),
                  ),
                  _DrawerItem(
                    icon: Icons.bluetooth,
                    label: 'Conectar vía Bluetooth',
                    enabled: widget.onConnectBluetooth != null,
                    onTap: () =>
                        _handleDrawerAction(context, widget.onConnectBluetooth),
                  ),
                ],
              ),
            ),

            const Spacer(),

            const Divider(height: 1, color: AppColors.border),

            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: AppColors.statusCritico,
              onTap: () async {
                Navigator.pop(context);
                context.read<PoolProvider>().clear();
                context.read<PoolDashboardProvider>().clear();
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

class _PoolItem extends StatelessWidget {
  final PoolModel pool;
  final bool isActive;
  final VoidCallback onTap;

  const _PoolItem({
    required this.pool,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.statusOptimo.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.statusOptimo : AppColors.border,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.pool,
              size: 16,
              color: isActive ? AppColors.statusOptimo : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pool.nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.statusOptimo
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pool.tipo != null)
                    Text(
                      pool.tipo!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.statusOptimo,
              ),
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
