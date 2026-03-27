import 'package:flutter/material.dart';
import 'package:aquasensors/features/auth/screens/register_screen.dart';
import 'package:aquasensors/features/auth/screens/email_verification_screen.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/account/screens/edit_profile_screen.dart';
import '../features/pool/screens/pool_screen.dart';

class AppRouter {
  AppRouter._();

  static const String login = AppConstants.routeLogin;
  static const String register = AppConstants.routeRegister;
  static const String verifyEmail = AppConstants.routeVerifyEmail;
  static const String home = AppConstants.routeHome;
  static const String reports = AppConstants.routeReports;
  static const String account = AppConstants.routeAccount;
  static const String editProfile = AppConstants.routeEditProfile;
  static const String pool = AppConstants.routePool;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      case register:
        return _fadeRoute(const RegisterScreen(), settings);
      case verifyEmail:
        final email = settings.arguments is String ? settings.arguments as String : null;
        return _fadeRoute(EmailVerificationScreen(email: email), settings);
      case home:
        return _fadeRoute(const HomeScreen(), settings);
      case reports:
        return _fadeRoute(const ReportsScreen(), settings);
      case account:
        return _fadeRoute(const AccountScreen(), settings);
      case editProfile:
        return _slideRoute(const EditProfileScreen(), settings);
      case pool:
        return _fadeRoute(const PoolScreen(), settings);
      default:
        return _fadeRoute(const LoginScreen(), settings);
    }
  }

  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRoute _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
