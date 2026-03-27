import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.headerTitle),
          if (subtitle != null)
            Text(subtitle!, style: AppTextStyles.headerSubtitle),
        ],
      ),
      actions: actions,
    );
  }
}

/// Botón "Conectar" que aparece en el header de Home
class ConnectButton extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const ConnectButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnecting)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: isConnected
                    ? const Color(0xFF4CAF50)
                    : Colors.white70,
              ),
            const SizedBox(width: 6),
            Text(
              isConnecting
                  ? 'Conectando...'
                  : (isConnected ? 'Conectado' : 'Conectar'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón hamburguesa — abre el Drawer lateral del Scaffold
class MenuIconButton extends StatelessWidget {
  const MenuIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: AppColors.textLight),
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}
