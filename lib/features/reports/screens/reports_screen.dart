import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/device_permission_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/sensor_provider.dart';
import '../../../shared/providers/arduino_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/connection_dialogs.dart';
import '../widgets/report_chart_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _poolId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      final pool = await _getFirstPool(user.id);
      if (pool != null && mounted) {
        setState(() => _poolId = pool);
        final now = DateTime.now();
        await context.read<SensorProvider>().loadHistoricalReadings(
          poolId: pool,
          from: DateTime(now.year, now.month, now.day),
          to: now,
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

  Future<void> _onPeriodChanged(
      String period, DateTime from, DateTime to) async {
    if (_poolId == null) return;
    await context.read<SensorProvider>().loadHistoricalReadings(
      poolId: _poolId!,
      from: from,
      to: to,
    );
  }

  double _avg(List<double> vals, double absMin, double absMax) {
    if (vals.isEmpty) return 0;
    final real = vals.map((v) => v * (absMax - absMin) + absMin).toList();
    return real.reduce((a, b) => a + b) / real.length;
  }

  double _min(List<double> vals, double absMin, double absMax) {
    if (vals.isEmpty) return 0;
    return vals
        .map((v) => v * (absMax - absMin) + absMin)
        .reduce((a, b) => a < b ? a : b);
  }

  double _max(List<double> vals, double absMin, double absMax) {
    if (vals.isEmpty) return 0;
    return vals
        .map((v) => v * (absMax - absMin) + absMin)
        .reduce((a, b) => a > b ? a : b);
  }

  Future<void> _showWifiConnectionDialog() async {
    if (_poolId == null) {
      _showSnack(context, 'conexión: primero registra una alberca');
      return;
    }

    final arduino = context.read<ArduinoProvider>();
    if (!arduino.hasBluetoothSetup) {
      _showSnack(
        context,
        'primero configura el ESP32 por Bluetooth y despues enlaza Wi-Fi local',
      );
      await _showBluetoothConnectionDialog();
      return;
    }

    final hasPermission = await DevicePermissionHelper.requestWifiAccess();
    if (!mounted) return;
    if (!hasPermission) {
      _showSnack(
        context,
        'permiso de ubicacion o Wi-Fi cercano requerido para usar Wi-Fi',
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
      _showSnack(context, 'permiso de Bluetooth requerido para continuar');
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

  @override
  Widget build(BuildContext context) {
    final sensorProv = context.watch<SensorProvider>();
    final phVals = sensorProv.phHistory;
    final clVals = sensorProv.cloroHistory;
    final tmpVals = sensorProv.tempHistory;
    final turbVals = sensorProv.turbHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        onConnectWifi: _showWifiConnectionDialog,
        onConnectBluetooth: _showBluetoothConnectionDialog,
      ),
      appBar: AppHeader(
        title: 'Reportes',
        subtitle: 'Descarga tus datos históricos',
        actions: const [MenuIconButton()],
      ),
      body: ListView(
        children: [
          ReportChartCard(
            title: 'pH',
            rangeLabel: 'Rango: ${AppConstants.phMin} – ${AppConstants.phMax}',
            color: AppColors.ph,
            unit: '',
            promedio: _avg(phVals, AppConstants.phAbsMin, AppConstants.phAbsMax),
            minimo: _min(phVals, AppConstants.phAbsMin, AppConstants.phAbsMax),
            maximo: _max(phVals, AppConstants.phAbsMin, AppConstants.phAbsMax),
            chartValues: phVals.isEmpty ? List.filled(12, 0.0) : phVals,
            chartLabels: const ['0h', '6h', '12h', '18h'],
            onPeriodChanged: _onPeriodChanged,
            onDownload: () => _showSnack(context, 'pH'),
          ),
          ReportChartCard(
            title: 'Cloro',
            rangeLabel: 'Rango: ${AppConstants.cloroMin} – ${AppConstants.cloroMax} ppm',
            color: AppColors.cloro,
            unit: ' ppm',
            promedio: _avg(clVals, AppConstants.cloroAbsMin, AppConstants.cloroAbsMax),
            minimo: _min(clVals, AppConstants.cloroAbsMin, AppConstants.cloroAbsMax),
            maximo: _max(clVals, AppConstants.cloroAbsMin, AppConstants.cloroAbsMax),
            chartValues: clVals.isEmpty ? List.filled(12, 0.0) : clVals,
            chartLabels: const ['0h', '6h', '12h', '18h'],
            onPeriodChanged: _onPeriodChanged,
            onDownload: () => _showSnack(context, 'Cloro'),
          ),
          ReportChartCard(
            title: 'Temperatura',
            rangeLabel: 'Rango: ${AppConstants.tempMin} – ${AppConstants.tempMax} °C',
            color: AppColors.temperatura,
            unit: ' °C',
            promedio: _avg(tmpVals, AppConstants.tempAbsMin, AppConstants.tempAbsMax),
            minimo: _min(tmpVals, AppConstants.tempAbsMin, AppConstants.tempAbsMax),
            maximo: _max(tmpVals, AppConstants.tempAbsMin, AppConstants.tempAbsMax),
            chartValues: tmpVals.isEmpty ? List.filled(12, 0.0) : tmpVals,
            chartLabels: const ['0h', '6h', '12h', '18h'],
            onPeriodChanged: _onPeriodChanged,
            onDownload: () => _showSnack(context, 'Temperatura'),
          ),
          ReportChartCard(
            title: 'Turbidez',
            rangeLabel: 'Rango: 0 – ${AppConstants.turbidezMax} NTU',
            color: AppColors.turbidez,
            unit: ' NTU',
            promedio: _avg(turbVals, AppConstants.turbidezMin, AppConstants.turbidezAbsMax),
            minimo: _min(turbVals, AppConstants.turbidezMin, AppConstants.turbidezAbsMax),
            maximo: _max(turbVals, AppConstants.turbidezMin, AppConstants.turbidezAbsMax),
            chartValues: turbVals.isEmpty ? List.filled(12, 0.0) : turbVals,
            chartLabels: const ['0h', '6h', '12h', '18h'],
            onPeriodChanged: _onPeriodChanged,
            onDownload: () => _showSnack(context, 'Turbidez'),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  void _showSnack(BuildContext context, String param) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando PDF de $param...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
