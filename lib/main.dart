import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/sensor_provider.dart';
import 'shared/providers/arduino_provider.dart';
import 'shared/providers/pool_provider.dart';
import 'shared/providers/pool_dashboard_provider.dart';
import 'services/notification_service.dart';
import 'services/session_policy_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  runApp(const AquaSensorsApp());
}

class AquaSensorsApp extends StatelessWidget {
  const AquaSensorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => ArduinoProvider()),
        ChangeNotifierProvider(create: (_) => PoolProvider()),
        ChangeNotifierProvider(create: (_) => PoolDashboardProvider()),
      ],
      child: MaterialApp(
        title: 'AquaSensors',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _SessionGate(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool? _allowAutoLogin;

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    final auth = context.read<AuthProvider>();
    final sensor = context.read<SensorProvider>();

    try {
      if (!auth.hasActiveSession) {
        await SessionPolicyService.instance.clearPolicy();
        if (!mounted) return;
        setState(() => _allowAutoLogin = false);
        return;
      }

      final allowed = await SessionPolicyService.instance.isSessionAllowed();
      if (!allowed) {
        sensor.stopRealtime();
        await NotificationService.instance.cancelAll();
        await auth.signOut();
        if (!mounted) return;
        setState(() => _allowAutoLogin = false);
        return;
      }

      try {
        await auth.handleAuthSessionUpdate();
      } catch (_) {
        // Si falla la sincronización del perfil, no bloqueamos el acceso.
      }

      if (!mounted) return;
      setState(() => _allowAutoLogin = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _allowAutoLogin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allowAutoLogin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allowAutoLogin == true) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
