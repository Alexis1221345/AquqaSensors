import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../shared/providers/arduino_provider.dart';

/// Widget que muestra el estado de conexión del ESP32 con indicador de proximidad y RSSI.
class ConnectionStatusCard extends StatelessWidget {
  final bool showProximityIndicator;
  final bool showAutoConnectToggle;
  final VoidCallback? onAutoProvisionTap;

  const ConnectionStatusCard({
    Key? key,
    this.showProximityIndicator = true,
    this.showAutoConnectToggle = true,
    this.onAutoProvisionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ArduinoProvider>(
      builder: (context, arduinoProvider, _) {
        if (!arduinoProvider.isConnected) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.cyan.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con icono de conexión
                Row(
                  children: [
                    Icon(
                      _getConnectionIcon(arduinoProvider.activeTransport),
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32 Conectado',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            arduinoProvider.connectionDetail,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Indicador de proximidad y RSSI
                if (showProximityIndicator &&
                    arduinoProvider.activeTransport == Esp32Transport.bluetooth)
                  _buildProximitySection(context, arduinoProvider),

                // Toggles de auto-conexión
                if (showAutoConnectToggle) ...[
                  const SizedBox(height: 12),
                  _buildAutoConnectToggles(context, arduinoProvider),
                ],

                // Botón de auto-provisión WiFi
                if (onAutoProvisionTap != null) ...[
                  const SizedBox(height: 12),
                  _buildAutoProvisionButton(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sección de proximidad con indicador de RSSI.
  Widget _buildProximitySection(
    BuildContext context,
    ArduinoProvider arduinoProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proximidad',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProximityColor(arduinoProvider.proximityState),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getProximityLabel(arduinoProvider.proximityState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Indicador visual de RSSI (barras de señal)
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final isFilled = index < arduinoProvider.signalStrength;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 4 + (index * 4).toDouble(),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? _getSignalColor(index)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${arduinoProvider.lastBleDeviceRssi ?? 0} dBm',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            arduinoProvider.proximityDescription,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggles para auto-conexión.
  Widget _buildAutoConnectToggles(
    BuildContext context,
    ArduinoProvider arduinoProvider,
  ) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            'Auto-cambiar a Bluetooth',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text(
            'Conectar automáticamente si está disponible',
            style: TextStyle(fontSize: 12),
          ),
          value: arduinoProvider.autoSwitchBluetooth,
          onChanged: (value) {
            arduinoProvider.setAutoBluetoothSwitch(value);
          },
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            'Auto-conectar por proximidad',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text(
            'Conectar cuando el celular esté cerca',
            style: TextStyle(fontSize: 12),
          ),
          value: arduinoProvider.autoConnectByProximity,
          onChanged: (value) {
            arduinoProvider.setAutoConnectByProximity(value);
          },
        ),
      ],
    );
  }

  /// Botón para auto-provisionar WiFi.
  Widget _buildAutoProvisionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onAutoProvisionTap,
        icon: const FaIcon(FontAwesomeIcons.wifi, size: 16),
        label: const Text('Auto-configurar WiFi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ============ Métodos auxiliares de UI ============

  /// Retorna el icono apropiado según el tipo de transporte.
  IconData _getConnectionIcon(Esp32Transport transport) {
    switch (transport) {
      case Esp32Transport.wifi:
        return FontAwesomeIcons.wifi;
      case Esp32Transport.bluetooth:
        return FontAwesomeIcons.bluetooth;
      case Esp32Transport.none:
        return FontAwesomeIcons.plug;
    }
  }

  /// Retorna el color para la proximidad.
  Color _getProximityColor(ProximityState proximity) {
    switch (proximity) {
      case ProximityState.veryNear:
        return Colors.green;
      case ProximityState.near:
        return Colors.blue;
      case ProximityState.far:
        return Colors.orange;
      case ProximityState.veryFar:
        return Colors.red;
      case ProximityState.unknown:
        return Colors.grey;
    }
  }

  /// Retorna la etiqueta de proximidad.
  String _getProximityLabel(ProximityState proximity) {
    switch (proximity) {
      case ProximityState.veryNear:
        return '🟢 Muy cerca';
      case ProximityState.near:
        return '🔵 Cerca';
      case ProximityState.far:
        return '🟠 Lejano';
      case ProximityState.veryFar:
        return '🔴 Muy lejano';
      case ProximityState.unknown:
        return '⚪ Desconocido';
    }
  }

  /// Retorna el color para cada barra de señal.
  Color _getSignalColor(int index) {
    if (index == 0) return Colors.green;
    if (index == 1) return Colors.blue;
    if (index == 2) return Colors.orange;
    return Colors.red;
  }
}
