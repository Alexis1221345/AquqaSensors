import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/arduino/esp32_bluetooth_service.dart';

Future<void> showEsp32WifiConnectDialog(
  BuildContext context, {
  required Future<void> Function(String ip) onConnectByIp,
  required Future<bool> Function({
    required String esp32Ip,
    required String ssid,
    required String password,
  }) onProvision,
  String? suggestedSsid,
}) {
  return showDialog(
    context: context,
    builder: (_) => _WifiConnectionDialog(
      onConnectByIp: onConnectByIp,
      onProvision: onProvision,
      suggestedSsid: suggestedSsid,
    ),
  );
}

Future<void> showEsp32BluetoothSetupDialog(
  BuildContext context, {
  required Future<List<BleDeviceCandidate>> Function() onScan,
  required Future<bool> Function(BleDeviceCandidate device) onConnect,
  required bool autoSwitchEnabled,
  required ValueChanged<bool> onAutoSwitchChanged,
}) {
  return showDialog(
    context: context,
    builder: (_) => _BluetoothConnectionDialog(
      onScan: onScan,
      onConnect: onConnect,
      autoSwitchEnabled: autoSwitchEnabled,
      onAutoSwitchChanged: onAutoSwitchChanged,
    ),
  );
}

class _WifiConnectionDialog extends StatefulWidget {
  final Future<void> Function(String ip) onConnectByIp;
  final Future<bool> Function({
    required String esp32Ip,
    required String ssid,
    required String password,
  }) onProvision;
  final String? suggestedSsid;

  const _WifiConnectionDialog({
    required this.onConnectByIp,
    required this.onProvision,
    this.suggestedSsid,
  });

  @override
  State<_WifiConnectionDialog> createState() => _WifiConnectionDialogState();
}

class _WifiConnectionDialogState extends State<_WifiConnectionDialog> {
  final _ipController =
      TextEditingController(text: AppConstants.esp32DefaultIp);
  late final TextEditingController _ssidController;
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.suggestedSsid ?? '');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitProvision() async {
    final ip = _ipController.text.trim();
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ip.isEmpty || ssid.isEmpty || password.isEmpty) return;

    setState(() => _isSubmitting = true);
    final ok = await widget.onProvision(
      esp32Ip: ip,
      ssid: ssid,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Credenciales enviadas. El ESP32 intentara unirse a la red Wi-Fi.'
              : 'No se pudo enviar la configuracion Wi-Fi al ESP32.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conectar por Wi-Fi', style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'El sistema puede leer el nombre de la red (SSID), pero no la contrasena guardada del telefono por restricciones del sistema.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'IP del ESP32',
              hintText: AppConstants.esp32DefaultIp,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ssidController,
            decoration: InputDecoration(
              labelText: 'Nombre de red Wi-Fi (SSID)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Contrasena Wi-Fi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitProvision,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Configurar ESP32'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await widget.onConnectByIp(_ipController.text.trim());
          },
          child: const Text('Conectar por IP'),
        ),
      ],
    );
  }
}

class _BluetoothConnectionDialog extends StatefulWidget {
  final Future<List<BleDeviceCandidate>> Function() onScan;
  final Future<bool> Function(BleDeviceCandidate device) onConnect;
  final bool autoSwitchEnabled;
  final ValueChanged<bool> onAutoSwitchChanged;

  const _BluetoothConnectionDialog({
    required this.onScan,
    required this.onConnect,
    required this.autoSwitchEnabled,
    required this.onAutoSwitchChanged,
  });

  @override
  State<_BluetoothConnectionDialog> createState() =>
      _BluetoothConnectionDialogState();
}

class _BluetoothConnectionDialogState extends State<_BluetoothConnectionDialog> {
  List<BleDeviceCandidate> _devices = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final devices = await widget.onScan();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  Future<void> _connect(BleDeviceCandidate device) async {
    setState(() => _loading = true);
    final ok = await widget.onConnect(device);
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Conectado por Bluetooth a ${device.name}.'
              : 'No se pudo conectar por Bluetooth.',
        ),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conectar por Bluetooth', style: AppTextStyles.heading3),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.autoSwitchEnabled,
              onChanged: widget.onAutoSwitchChanged,
              title: const Text('Cambio automatico a Bluetooth cercano'),
              subtitle: const Text(
                'Usa Wi-Fi a distancia y cambia a Bluetooth cuando el ESP32 este cerca.',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              const Text(
                'No se detectaron dispositivos ESP32. Acerca el telefono y vuelve a escanear.',
                style: AppTextStyles.bodyMedium,
              )
            else
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (_, index) {
                    final item = _devices[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth_searching),
                      title: Text(item.name),
                      subtitle: Text('RSSI ${item.rssi ?? 0} dBm'),
                      trailing: TextButton(
                        onPressed: () => _connect(item),
                        child: const Text('Conectar'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _scan, child: const Text('Reescanear')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

