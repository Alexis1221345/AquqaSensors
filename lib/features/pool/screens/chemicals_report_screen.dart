import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/device_permission_helper.dart';
import '../../../data/models/pool_dashboard_model.dart';
import '../../../data/supabase/supabase_chemicals_service.dart';
import '../../../shared/providers/arduino_provider.dart';
import '../../../shared/providers/pool_dashboard_provider.dart';
import '../../../shared/providers/pool_provider.dart';
import '../../../shared/providers/sensor_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/connection_dialogs.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../home/widgets/bar_chart_widget.dart';
import '../../reports/widgets/download_pdf_button.dart';
import '../../reports/widgets/period_selector.dart';

class ChemicalsReportScreen extends StatefulWidget {
  const ChemicalsReportScreen({super.key});

  @override
  State<ChemicalsReportScreen> createState() => _ChemicalsReportScreenState();
}

class _ChemicalsReportScreenState extends State<ChemicalsReportScreen> {
  final SupabaseChemicalsService _chemicalsService = SupabaseChemicalsService();

  String _selectedPeriod = 'semana';
  List<ChemicalDoseHistoryModel> _doseHistory = [];
  bool _loadingDoses = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final poolId = context.read<PoolProvider>().activePoolId;
    if (poolId == null) return;

    setState(() => _loadingDoses = true);
    final now = DateTime.now();
    final from = _periodFrom(_selectedPeriod, now);

    try {
      final data = await _chemicalsService.getDoseHistory(
        poolId: poolId,
        from: from,
        to: now,
      );
      if (!mounted) return;
      setState(() => _doseHistory = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _doseHistory = []);
      _showSnack(context, 'Error al cargar historial de dosificación', isError: true);
    } finally {
      if (mounted) setState(() => _loadingDoses = false);
    }
  }

  DateTime _periodFrom(String period, DateTime now) {
    return switch (period) {
      'dia' => DateTime(now.year, now.month, now.day),
      'semana' => now.subtract(const Duration(days: 7)),
      'quincenal' => now.subtract(const Duration(days: 15)),
      'mensual' => now.subtract(const Duration(days: 30)),
      _ => now.subtract(const Duration(days: 7)),
    };
  }

  Future<void> _onPeriodChanged(String period) async {
    setState(() => _selectedPeriod = period);
    await _loadData();
  }

  List<ChemicalDoseHistoryModel> _dosesFor(String quimico) {
    final dosis = _doseHistory.where((d) => d.quimico == quimico).toList();
    dosis.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return dosis;
  }

  List<String> get _uniqueQuimicos {
    return _doseHistory.map((d) => d.quimico).toSet().toList();
  }


  Color _colorForQuimico(String quimico) {
    return switch (quimico) {
      'cloro' => AppColors.cloro,
      'cloro_choque' => AppColors.statusAlerta,
      'subir_ph' => AppColors.ph,
      'bajar_ph' => const Color(0xFFE91E63),
      'alcalinidad' => AppColors.temperatura,
      'turbidez' => AppColors.turbidez,
      'algicida' => const Color(0xFF009688),
      _ => AppColors.textSecondary,
    };
  }

  Future<void> _showWifiConnectionDialog() async {
    final poolId = context.read<PoolProvider>().activePoolId;
    if (poolId == null) {
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
            poolId: poolId,
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

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSnack(BuildContext context, String param, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isError ? param : 'Generando PDF de $param...'),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? AppColors.statusCritico : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePoolId = context.watch<PoolProvider>().activePoolId;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        onConnectWifi: _showWifiConnectionDialog,
        onConnectBluetooth: _showBluetoothConnectionDialog,
        onPoolChanged: (poolId) async {
          await context.read<PoolDashboardProvider>().loadDashboard(poolId);
          if (!mounted) return;
          _showInfoMessage('Alberca activa actualizada');
          await _loadData();
        },
      ),
      appBar: const AppHeader(
        title: 'Dosificación',
        subtitle: 'Historial de químicos aplicados',
        actions: [MenuIconButton()],
      ),
      body: activePoolId == null
          ? const Center(child: Text('Selecciona una alberca primero'))
          : _buildBody(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    if (_loadingDoses) {
      return const LoadingWidget(message: 'Cargando historial...');
    }

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: PeriodSelector(
          selected: _selectedPeriod,
          onChanged: (value) => _onPeriodChanged(value),
        ),
      ),
    ];

    if (_doseHistory.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: _EmptyState(),
        ),
      );
    } else {
      children.addAll(_uniqueQuimicos.map((quimico) {
        final dosis = _dosesFor(quimico);
        return _ChemicalChartCard(
          quimico: quimico,
          dosis: dosis,
          color: _colorForQuimico(quimico),
          selectedPeriod: _selectedPeriod,
          onDownload: () => _showSnack(context, quimico),
        );
      }));
    }

    children.add(const SizedBox(height: 16));

    return ListView(
      children: children,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Sin dosis registradas',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          Text(
            'en el período seleccionado',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChemicalChartCard extends StatefulWidget {
  final String quimico;
  final List<ChemicalDoseHistoryModel> dosis;
  final Color color;
  final String selectedPeriod;
  final VoidCallback onDownload;

  const _ChemicalChartCard({
    required this.quimico,
    required this.dosis,
    required this.color,
    required this.selectedPeriod,
    required this.onDownload,
  });

  @override
  State<_ChemicalChartCard> createState() => _ChemicalChartCardState();
}

class _ChemicalChartCardState extends State<_ChemicalChartCard> {
  double _chartScaleMax(BuildContext context) {
    final dashboard = context.watch<PoolDashboardProvider>().dashboard;
    final recommended = dashboard?.dosisRecomendadas.where(
      (d) => d.quimico == widget.quimico,
    );
    if (recommended != null && recommended.isNotEmpty) {
      final dose = recommended.first;
      if (dose.unidad == 'ml' && dose.cantidad > 0) {
        return max(dose.cantidad * 2, 100);
      }
    }
    return 500;
  }

  List<double> _normalizeValues(List<double> values, double scaleMax) {
    if (values.isEmpty) return [];
    if (scaleMax <= 0) return List.filled(values.length, 0.0);
    return values.map((v) => (v / scaleMax).clamp(0.0, 1.0)).toList();
  }

  String get _quimicoLabel {
    return {
          'cloro': 'Cloro',
          'cloro_choque': 'Cloro Choque',
          'subir_ph': 'Subir pH',
          'bajar_ph': 'Bajar pH',
          'alcalinidad': 'Alcalinidad',
          'turbidez': 'Floculante',
          'algicida': 'Algicida',
        }[widget.quimico] ??
        widget.quimico;
  }

  List<String> _labelsForPeriod(
    String period,
    List<ChemicalDoseHistoryModel> dosis,
  ) {
    if (dosis.isEmpty) return [];

    final allLabels = dosis.map((x) {
      if (period == 'dia') {
        return DateFormatter.hourLabel(x.timestamp.toLocal());
      }
      final d = x.timestamp.toLocal();
      return '${d.day}/${d.month}';
    }).toList();

    if (allLabels.length <= 5) return allLabels;

    final result = <String>[];
    for (var i = 0; i < 5; i++) {
      final index = ((i * (allLabels.length - 1)) / 4).round();
      result.add(allLabels[index]);
    }
    return result;
  }

  String _downloadLabel(String period) {
    final now = DateTime.now();
    final name = {
      'dia': 'Diario',
      'semana': 'Semanal',
      'quincenal': 'Quincenal',
      'mensual': 'Mensual',
    }[period]!;
    return '$name • ${DateFormatter.toDisplay(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final mlValues = widget.dosis.map((d) => d.cantidadMl ?? 0.0).toList();
    final scaleMax = _chartScaleMax(context);
    final normalized = _normalizeValues(mlValues, scaleMax);
    final total = mlValues.isEmpty ? 0.0 : mlValues.reduce((a, b) => a + b);
    final maxVal = mlValues.isEmpty ? 0.0 : mlValues.reduce(max);
    final minVal = mlValues.isEmpty ? 0.0 : mlValues.reduce(min);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _quimicoLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Text(
                'Total período',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DoseStatsRow(total: total, minDosis: minVal, maxDosis: maxVal),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.timeline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Aplicaciones en el período',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BarChartWidget(
            values: normalized,
            barColor: widget.color,
            labels: _labelsForPeriod(widget.selectedPeriod, widget.dosis),
            maxBars: 30,
          ),
          const SizedBox(height: 14),
          DownloadPdfButton(
            parameter: _quimicoLabel,
            periodLabel: _downloadLabel(widget.selectedPeriod),
            color: widget.color,
            onTap: widget.onDownload,
          ),
        ],
      ),
    );
  }
}

class _DoseStatsRow extends StatelessWidget {
  final double total;
  final double minDosis;
  final double maxDosis;

  const _DoseStatsRow({
    required this.total,
    required this.minDosis,
    required this.maxDosis,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DoseStatCell(label: 'Total', value: total),
        _DoseStatCell(label: 'Mín dosis', value: minDosis),
        _DoseStatCell(label: 'Máx dosis', value: maxDosis),
      ],
    );
  }
}

class _DoseStatCell extends StatelessWidget {
  final String label;
  final double value;

  const _DoseStatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(value)} ml',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}
