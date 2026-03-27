import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 72,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}
