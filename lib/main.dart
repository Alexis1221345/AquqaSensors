import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/sensor_provider.dart';
import 'shared/providers/arduino_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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
      ],
      child: MaterialApp(
        title: 'AquaSensors',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.login,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}