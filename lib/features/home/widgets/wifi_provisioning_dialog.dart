import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../shared/providers/arduino_provider.dart';

/// Diálogo para provisionar WiFi automáticamente en el ESP32.
/// Detecta la red actual del teléfono y pide la contraseña para enviarla al ESP32.
class WifiProvisioningDialog extends StatefulWidget {
  final String esp32Ip;

  const WifiProvisioningDialog({
    Key? key,
    required this.esp32Ip,
  }) : super(key: key);

  @override
  State<WifiProvisioningDialog> createState() => _WifiProvisioningDialogState();
}

class _WifiProvisioningDialogState extends State<WifiProvisioningDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _detectedSsid;
  bool _isLoading = true;
  bool _showPassword = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentWifi();
  }

  /// Carga el SSID del WiFi actual.
  Future<void> _loadCurrentWifi() async {
    try {
      final arduinoProvider =
          context.read<ArduinoProvider>();
      final ssid = await arduinoProvider.getCurrentWifiSsid();
      
      setState(() {
        _detectedSsid = ssid;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'Error al detectar WiFi';
        _isLoading = false;
      });
    }
  }

  /// Intenta provisionar el ESP32 con las credenciales.
  Future<void> _provision() async {
    if (_detectedSsid == null || _detectedSsid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se detectó red WiFi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la contraseña del WiFi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final arduinoProvider = context.read<ArduinoProvider>();

      // Intentamos provisioning inteligente: probar la IP proporcionada
      // y, si no responde, probar el SoftAP por defecto 192.168.4.1.
      final success = await arduinoProvider.autoProvisionWithCurrentNetwork(
        esp32Ip: widget.esp32Ip,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ WiFi configurado en el ESP32'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al configurar WiFi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const FaIcon(FontAwesomeIcons.wifi, color: Colors.blue),
          const SizedBox(width: 12),
          const Text('Configurar WiFi en ESP32'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red detectada
            Text(
              'Red detectada:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.networkWired,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoading
                        ? const Text(
                            'Detectando WiFi...',
                            style: TextStyle(color: Colors.grey),
                          )
                        : _detectedSsid == null
                            ? const Text(
                                'No se detectó red',
                                style: TextStyle(color: Colors.red),
                              )
                            : Text(
                                _detectedSsid!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de contraseña
            Text(
              'Contraseña WiFi:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Ingresa la contraseña',
                prefixIcon: const FaIcon(FontAwesomeIcons.lock, size: 16),
                suffixIcon: IconButton(
                  icon: FaIcon(
                    _showPassword
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // Mensaje de información
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '💡 El ESP32 se conectará a esta red WiFi después de recibir la configuración.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue.shade900,
                ),
              ),
            ),

            // Estado de provisión
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _provision,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const FaIcon(FontAwesomeIcons.check, size: 14),
          label: const Text('Configurar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Función auxiliar para mostrar el diálogo de provisioning WiFi.
Future<bool?> showWifiProvisioningDialog(
  BuildContext context, {
  required String esp32Ip,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => WifiProvisioningDialog(esp32Ip: esp32Ip),
  );
}
