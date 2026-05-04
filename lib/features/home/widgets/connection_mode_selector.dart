import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ConnectionMode { wifi, bluetooth }

/// Diálogo que permite al usuario elegir entre conectar vía WiFi o Bluetooth.
/// Elimina la necesidad de pedir ambas opciones secuencialmente.
class ConnectionModeSelector extends StatefulWidget {
  final VoidCallback onWifiSelected;
  final VoidCallback onBluetoothSelected;

  const ConnectionModeSelector({
    Key? key,
    required this.onWifiSelected,
    required this.onBluetoothSelected,
  }) : super(key: key);

  @override
  State<ConnectionModeSelector> createState() => _ConnectionModeSelectorState();
}

class _ConnectionModeSelectorState extends State<ConnectionModeSelector> {
  ConnectionMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.cyan.shade50],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y título
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.plug,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Conectar ESP32',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige un método de conexión',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Opción WiFi
              _ConnectionOption(
                mode: ConnectionMode.wifi,
                icon: FontAwesomeIcons.wifi,
                title: 'Conectar vía WiFi',
                description: 'Conecta a la red local WiFi del ESP32',
                isSelected: _selectedMode == ConnectionMode.wifi,
                onTap: () => setState(
                  () => _selectedMode = ConnectionMode.wifi,
                ),
              ),
              const SizedBox(height: 12),

              // Opción Bluetooth
              _ConnectionOption(
                mode: ConnectionMode.bluetooth,
                icon: FontAwesomeIcons.bluetooth,
                title: 'Conectar vía Bluetooth',
                description: 'Empareja el dispositivo por Bluetooth',
                isSelected: _selectedMode == ConnectionMode.bluetooth,
                onTap: () => setState(
                  () => _selectedMode = ConnectionMode.bluetooth,
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedMode == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              if (_selectedMode == ConnectionMode.wifi) {
                                widget.onWifiSelected();
                              } else {
                                widget.onBluetoothSelected();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          color: _selectedMode == null
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget individual para cada opción de conexión.
class _ConnectionOption extends StatelessWidget {
  final ConnectionMode mode;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConnectionOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.12)
              : Colors.white.withOpacity(0.5),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade400
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                icon,
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blue.shade900
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Radio button
            Radio<ConnectionMode>(
              value: mode,
              groupValue: isSelected ? mode : null,
              onChanged: (_) => onTap(),
              activeColor: Colors.blue.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

/// Función auxiliar para mostrar el selector de conexión.
Future<void> showConnectionModeSelector(
  BuildContext context, {
  required VoidCallback onWifiSelected,
  required VoidCallback onBluetoothSelected,
}) async {
  return showDialog(
    context: context,
    builder: (context) => ConnectionModeSelector(
      onWifiSelected: onWifiSelected,
      onBluetoothSelected: onBluetoothSelected,
    ),
  );
}
