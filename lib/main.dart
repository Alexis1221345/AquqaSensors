import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        // Use builder to add a debug overlay in debug mode that helps
        // inspect device pixels, DPR and tap coordinates.
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              if (kDebugMode) const DebugPixelInspector(),
            ],
          );
        },
      ),
    );
  }
}

// Debug-only widget that displays device pixel information and last tap
// coordinates (logical and physical). It only shows in debug builds.
class DebugPixelInspector extends StatefulWidget {
  const DebugPixelInspector({super.key});

  @override
  State<DebugPixelInspector> createState() => _DebugPixelInspectorState();
}

class _DebugPixelInspectorState extends State<DebugPixelInspector> {
  Offset? _lastTapLogical;
  Offset? _lastTapPhysical;

  void _handlePointerDown(PointerDownEvent event) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    setState(() {
      _lastTapLogical = event.localPosition;
      _lastTapPhysical = event.localPosition * dpr;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dpr = mq.devicePixelRatio;
    final logicalSize = mq.size;
    final physicalSize = logicalSize * dpr;

    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.all(8),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEBUG PIXEL INSPECTOR'),
                      const SizedBox(height: 6),
                      Text('DevicePixelRatio: ${dpr.toStringAsFixed(2)}'),
                      Text('Logical size: ${logicalSize.width.toStringAsFixed(0)} x ${logicalSize.height.toStringAsFixed(0)}'),
                      Text('Physical size: ${physicalSize.width.toStringAsFixed(0)} x ${physicalSize.height.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      Text('Last tap (logical): ${_lastTapLogical != null ? '${_lastTapLogical!.dx.toStringAsFixed(1)}, ${_lastTapLogical!.dy.toStringAsFixed(1)}' : '-'}'),
                      Text('Last tap (physical): ${_lastTapPhysical != null ? '${_lastTapPhysical!.dx.toStringAsFixed(1)}, ${_lastTapPhysical!.dy.toStringAsFixed(1)}' : '-'}'),
                      const SizedBox(height: 6),
                      const Text('Tip: toca cualquier lugar para ver coordenadas'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/Pantalla/pantalla_carga.png'),
          fit: BoxFit.cover,
        ),
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
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    try {
      await SupabaseConfig.initialize();
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermissions();
      await _resolveSession();
    } catch (_) {
      if (!mounted) return;
      setState(() => _allowAutoLogin = false);
    }
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
      return const _LoadingSplash();
    }

    if (_allowAutoLogin == true) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
