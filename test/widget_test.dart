import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aquasensors/shared/providers/auth_provider.dart';
import 'package:aquasensors/shared/providers/sensor_provider.dart';
import 'package:aquasensors/shared/providers/arduino_provider.dart';
import 'package:aquasensors/features/auth/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login screen renders correctly', (WidgetTester tester) async {

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SensorProvider()),
          ChangeNotifierProvider(create: (_) => ArduinoProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verifica que los elementos del login estén presentes
    expect(find.text('AquaSensors'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}