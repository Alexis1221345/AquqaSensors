import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/device_permission_helper.dart';
import '../../../core/utils/sensor_status_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/sensor_provider.dart';
import '../../../shared/providers/arduino_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/connection_dialogs.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../widgets/sensor_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _poolId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      final pool = await _getFirstPool(user.id);
      if (mounted) {
        setState(() => _poolId = pool);
        await context.read<SensorProvider>().loadLatestReadings(
              pool ?? 'sin-alberca',
            );
      }
    });
  }

  Future<String?> _getFirstPool(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from(AppConstants.tablePools)
          .select('id')
          .eq('owner_id', userId)
          .limit(1)
          .maybeSingle();
      return data?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showWifiConnectionDialog() async {
    if (_poolId == null) {
      _showInfoMessage('Primero registra una alberca para conectar el ESP32.');
      return;
    }

    final arduino = context.read<ArduinoProvider>();
    if (!arduino.hasBluetoothSetup) {
      _showInfoMessage(
        'Primero configura el ESP32 por Bluetooth y despues enlaza la red Wi-Fi local.',
      );
      await _showBluetoothConnectionDialog();
      return;
    }

    final hasPermission = await DevicePermissionHelper.requestWifiAccess();
    if (!mounted) return;
    if (!hasPermission) {
      _showInfoMessage(
        'Se necesita permiso de ubicacion o Wi-Fi cercano para consultar la red actual del dispositivo.',
      );
      return;
    }

    final currentSsid = await arduino.getCurrentWifiSsid();
    if (!mounted) return;

    await showEsp32WifiConnectDialog(
      context,
      suggestedSsid: currentSsid,
      onConnectByIp: (ip) => context.read<SensorProvider>().connectToEsp32(
            poolId: _poolId!,
            ip: ip.isNotEmpty ? ip : null,
          ),
      onProvision: ({
        required esp32Ip,
        required ssid,
        required password,
      }) => arduino.provisionEsp32Wifi(
        esp32Ip: esp32Ip,
        ssid: ssid,
        password: password,
      ),
    );
  }

  Future<void> _showBluetoothConnectionDialog() async {
    final hasPermission = await DevicePermissionHelper.requestBluetoothAccess();
    if (!mounted) return;
    if (!hasPermission) {
      _showInfoMessage(
        'Se necesitan permisos de Bluetooth para iniciar esta conexión.',
      );
      return;
    }

    final arduino = context.read<ArduinoProvider>();
    await showEsp32BluetoothSetupDialog(
      context,
      onScan: arduino.scanBluetoothDevices,
      onConnect: arduino.connectBluetooth,
      autoSwitchEnabled: arduino.autoSwitchBluetooth,
      onAutoSwitchChanged: arduino.setAutoBluetoothSwitch,
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final sensorProv = context.watch<SensorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        onConnectWifi: _showWifiConnectionDialog,
        onConnectBluetooth: _showBluetoothConnectionDialog,
      ),
      appBar: AppHeader(
        title: '¡Hola, ${user?.nombre ?? 'Usuario'}!',
        subtitle: 'Estado en tiempo real',
        actions: const [MenuIconButton()],
      ),
      body: sensorProv.isLoading
          ? const LoadingWidget(message: 'Cargando sensores...')
          : _buildBody(sensorProv),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(SensorProvider sensorProv) {
    final ph = sensorProv.ph ?? 0.0;
    final cloro = sensorProv.cloro ?? 0.0;
    final temp = sensorProv.temperatura ?? 0.0;
    final turbidez = sensorProv.turbidez ?? 0.0;
    final sinDatos = sensorProv.ph == null;

    final phNorm = SensorStatusHelper.normalizeForGauge(
        ph, AppConstants.phAbsMin, AppConstants.phAbsMax);
    final cloroNorm = SensorStatusHelper.normalizeForGauge(
        cloro, AppConstants.cloroAbsMin, AppConstants.cloroAbsMax);
    final tempNorm = SensorStatusHelper.normalizeForGauge(
        temp, AppConstants.tempAbsMin, AppConstants.tempAbsMax);
    final turbNorm = SensorStatusHelper.normalizeForGauge(
        turbidez, AppConstants.turbidezMin, AppConstants.turbidezAbsMax);

    return ListView(
      children: [
        if (sinDatos)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esperando datos del sensor. Conecta el ESP32 o espera la siguiente lectura.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        SensorCard(
          title: 'Nivel de pH',
          icon: Icons.science_outlined,
          iconColor: AppColors.ph,
          value: ph,
          unit: '',
          rangeLabel: sinDatos
              ? 'Sin datos aún'
              : 'Rango: ${AppConstants.phMin} – ${AppConstants.phMax}',
          status: SensorStatusHelper.phStatus(ph),
          gaugeNormalized: phNorm,
          dailyValues: sensorProv.phHistory.isEmpty
              ? List.filled(12, 0.0)
              : sensorProv.phHistory,
          dailyLabels: const ['0h', '6h', '12h', '18h'],
        ),
        SensorCard(
          title: 'Nivel de Cloro',
          icon: Icons.colorize_outlined,
          iconColor: AppColors.cloro,
          value: cloro,
          unit: 'ppm',
          rangeLabel: sinDatos
              ? 'Sin datos aún'
              : 'Rango: ${AppConstants.cloroMin} – ${AppConstants.cloroMax} ppm',
          status: SensorStatusHelper.cloroStatus(cloro),
          gaugeNormalized: cloroNorm,
          dailyValues: sensorProv.cloroHistory.isEmpty
              ? List.filled(12, 0.0)
              : sensorProv.cloroHistory,
          dailyLabels: const ['0h', '6h', '12h', '18h'],
        ),
        SensorCard(
          title: 'Temperatura',
          icon: Icons.device_thermostat,
          iconColor: AppColors.temperatura,
          value: temp,
          unit: ' °C',
          rangeLabel: sinDatos
              ? 'Sin datos aún'
              : 'Rango: ${AppConstants.tempMin} – ${AppConstants.tempMax} °C',
          status: SensorStatusHelper.temperaturaStatus(temp),
          gaugeNormalized: tempNorm,
          dailyValues: sensorProv.tempHistory.isEmpty
              ? List.filled(12, 0.0)
              : sensorProv.tempHistory,
          dailyLabels: const ['0h', '6h', '12h', '18h'],
        ),
        SensorCard(
          title: 'Turbidez',
          icon: Icons.water_outlined,
          iconColor: AppColors.turbidez,
          value: turbidez,
          unit: ' NTU',
          rangeLabel: sinDatos
              ? 'Sin datos aún'
              : 'Rango: 0 – ${AppConstants.turbidezMax} NTU',
          status: SensorStatusHelper.turbidezStatus(turbidez),
          gaugeNormalized: turbNorm,
          dailyValues: sensorProv.turbHistory.isEmpty
              ? List.filled(12, 0.0)
              : sensorProv.turbHistory,
          dailyLabels: const ['0h', '6h', '12h', '18h'],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

