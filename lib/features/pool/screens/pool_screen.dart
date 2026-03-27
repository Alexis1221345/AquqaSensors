import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/device_permission_helper.dart';
import '../../../data/models/pool_model.dart';
import '../../../data/supabase/supabase_storage_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/arduino_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/connection_dialogs.dart';
import '../widgets/pool_3d_preview.dart';
import 'add_pool_sheet.dart';

class PoolScreen extends StatefulWidget {
  const PoolScreen({super.key});

  @override
  State<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends State<PoolScreen> {
  final _storageService = SupabaseStorageService();
  bool _uploadingImage = false;
  bool _loadingPool = true;
  PoolModel? _pool;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPool());
  }

  Future<void> _loadPool() async {
    setState(() => _loadingPool = true);
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _loadingPool = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from(AppConstants.tablePools)
          .select()
          .eq('owner_id', user.id)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _pool = data != null
              ? PoolModel.fromJson(data)
              : null;
          _loadingPool = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPool = false);
    }
  }

  Future<void> _uploadImage() async {
    if (_pool == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      await _storageService.uploadPoolImage(
        poolId: _pool!.id,
        imageFile: File(picked.path),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida correctamente.')),
        );
        _loadPool();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppColors.statusCritico,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _showWifiConnectionDialog() async {
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
        'Se necesita permiso de ubicacion o Wi-Fi cercano para consultar la red actual.',
      );
      return;
    }

    final currentSsid = await arduino.getCurrentWifiSsid();
    if (!mounted) return;

    await showEsp32WifiConnectDialog(
      context,
      suggestedSsid: currentSsid,
      onConnectByIp: (ip) => context.read<ArduinoProvider>().connect(
            ip.isNotEmpty ? ip : AppConstants.esp32DefaultIp,
          ),
      onProvision: ({
        required esp32Ip,
        required ssid,
        required password,
      }) => context.read<ArduinoProvider>().provisionEsp32Wifi(
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
    final arduino = context.watch<ArduinoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B2D4A),
      drawer: AppDrawer(
        onConnectWifi: _showWifiConnectionDialog,
        onConnectBluetooth: _showBluetoothConnectionDialog,
      ),
      appBar: AppHeader(
        title: 'Alberca',
        subtitle: 'Gestión y monitoreo',
        actions: const [MenuIconButton()],
      ),
      body: Stack(
        children: [
          const _PoolBlueprintBackground(),
          if (_loadingPool)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            _PoolContent(
              pool: _pool,
              isUploadingImage: _uploadingImage,
              onAddPool: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => AddPoolSheet(onSaved: _loadPool),
              ),
              onUploadPhoto: _uploadImage,
              statusCard: _Esp32StatusCard(
                isConnected: arduino.isConnected,
                isConnecting: arduino.isConnecting,
                ip: arduino.currentIp,
                detail: arduino.connectionDetail,
                error: arduino.errorMessage,
                onDisconnect: () => arduino.disconnect(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class _PoolContent extends StatelessWidget {
  final PoolModel? pool;
  final bool isUploadingImage;
  final VoidCallback onAddPool;
  final VoidCallback onUploadPhoto;
  final Widget statusCard;

  const _PoolContent({
    required this.pool,
    required this.isUploadingImage,
    required this.onAddPool,
    required this.onUploadPhoto,
    required this.statusCard,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        const SizedBox(height: 6),
        Pool3dPreview(
          largoM: pool?.largoM,
          anchoM: pool?.anchoM,
          diametroM: pool?.diametroM,
          profMinimaM: pool?.profMinimaM,
          profMaximaM: pool?.profMaximaM,
          showDimensionBadge: true,
          height: 280,
        ),
        const SizedBox(height: 10),
        statusCard,
        const SizedBox(height: 12),
        _PoolInfoGlassCard(pool: pool),
        const SizedBox(height: 16),
        _PrimaryPoolActionButton(
          hasPool: pool != null,
          isLoading: isUploadingImage,
          onAddPool: onAddPool,
          onUploadPhoto: onUploadPhoto,
        ),
      ],
    );
  }
}

class _PrimaryPoolActionButton extends StatelessWidget {
  final bool hasPool;
  final bool isLoading;
  final VoidCallback onAddPool;
  final VoidCallback onUploadPhoto;

  const _PrimaryPoolActionButton({
    required this.hasPool,
    required this.isLoading,
    required this.onAddPool,
    required this.onUploadPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x553596FF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : (hasPool ? onUploadPhoto : onAddPool),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(hasPool ? Icons.add_photo_alternate_outlined : Icons.add),
        label: Text(
          isLoading
              ? 'Subiendo imagen...'
              : (hasPool ? 'Agregar foto de alberca' : 'Agregar alberca'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

class _PoolInfoGlassCard extends StatelessWidget {
  final PoolModel? pool;

  const _PoolInfoGlassCard({required this.pool});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la alberca',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Nombre de ubicación', pool?.nombre ?? 'Sin alberca registrada'),
          const SizedBox(height: 8),
          _infoRow('Dimensiones', _dimensionsLabel(pool)),
          const SizedBox(height: 8),
          _infoRow('Ubicación', pool?.ubicacion ?? 'No especificada'),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _dimensionsLabel(PoolModel? pool) {
    if (pool == null) return 'Sin medidas';
    final largo = pool.largoM ?? pool.diametroM;
    final ancho = pool.anchoM ?? pool.diametroM;
    final pMin = pool.profMinimaM;
    final pMax = pool.profMaximaM;

    if (largo == null || ancho == null || pMin == null || pMax == null) {
      return 'Medidas no disponibles';
    }

    return '${_fmt(largo)}m x ${_fmt(ancho)}m x ${_fmt((pMin + pMax) / 2)}m';
  }

  String _fmt(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? value.toStringAsFixed(0) : fixed;
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PoolBlueprintBackground extends StatelessWidget {
  const _PoolBlueprintBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0C3E66),
                  const Color(0xFF0B2D4A),
                  const Color(0xFF102238),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _BlueprintGridPainter()),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
            child: Container(
              color: Colors.blue.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const majorStep = 64.0;
    const minorStep = 16.0;

    final minor = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.05)
      ..strokeWidth = 0.7;

    final major = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += minorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 0; y <= size.height; y += minorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }

    for (double x = 0; x <= size.width; x += majorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
    }
    for (double y = 0; y <= size.height; y += majorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridPainter oldDelegate) => false;
}

// ── Card estado ESP32 ─────────────────────────────────────────────────────────

class _Esp32StatusCard extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String ip;
  final String detail;
  final String? error;
  final VoidCallback onDisconnect;

  const _Esp32StatusCard({
    required this.isConnected,
    required this.isConnecting,
    required this.ip,
    required this.detail,
    required this.error,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {

    return _GlassCard(
      child: Row(
        children: [
          Icon(
            isConnected
                ? Icons.memory_rounded
                : (error != null ? Icons.portable_wifi_off : Icons.memory_outlined),
            color: isConnected ? const Color(0xFF78F8C0) : Colors.white70,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? 'ESP32 conectado'
                      : (isConnecting ? 'Conectando...' : 'ESP32 desconectado'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? const Color(0xFFB8FFE5) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected
                      ? detail
                      : 'Abre el menú para conectar por Wi‑Fi o Bluetooth',
                  style: TextStyle(
                    fontSize: 12,
                    color: error != null ? AppColors.statusCritico : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFC6C6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isConnected)
            TextButton(
              onPressed: onDisconnect,
              child: const Text(
                'Desconectar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
