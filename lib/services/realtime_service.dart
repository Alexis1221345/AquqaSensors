import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import 'notification_service.dart';

class RealtimeService {
  static final RealtimeService instance = RealtimeService._();
  RealtimeService._();

  final Map<String, RealtimeChannel> _channels = {};

  Future<void> subscribeToPool({
    required String poolId,
    required String poolNombre,
    required void Function(String parametro, double valor, String status)
        onNewReading,
    required void Function(String parametro, String nivel, String mensaje,
            double valor)
        onNewAlert,
    required void Function(String quimicoNombre, double pct) onInventarioBajo,
  }) async {
    try {
      await unsubscribeFromPool(poolId);

      final readingsChannel = SupabaseConfig.client.channel('pool-$poolId-readings');
      _attachReadingChannel(
        channel: readingsChannel,
        poolId: poolId,
        poolNombre: poolNombre,
        onNewReading: onNewReading,
      );
      readingsChannel.subscribe();
      _channels[_key(poolId, 'readings')] = readingsChannel;

      final alertsChannel = SupabaseConfig.client.channel('pool-$poolId-alerts');
      _attachAlertChannel(
        channel: alertsChannel,
        poolId: poolId,
        poolNombre: poolNombre,
        onNewAlert: onNewAlert,
        onInventarioBajo: onInventarioBajo,
      );
      alertsChannel.subscribe();
      _channels[_key(poolId, 'alerts')] = alertsChannel;
    } catch (e) {
      debugPrint('RealtimeService.subscribeToPool error: $e');
    }
  }

  Future<void> subscribeToAllPools({
    required List<({String id, String nombre})> pools,
    required void Function(String poolId, String parametro, double valor,
            String status)
        onNewReading,
    required void Function(String poolId, String parametro, String nivel,
            String mensaje)
        onNewAlert,
    required void Function(String poolId, String quimicoNombre, double pct)
        onInventarioBajo,
  }) async {
    try {
      for (final pool in pools) {
        await subscribeToPool(
          poolId: pool.id,
          poolNombre: pool.nombre,
          onNewReading: (parametro, valor, status) => onNewReading(
            pool.id,
            parametro,
            valor,
            status,
          ),
          onNewAlert: (parametro, nivel, mensaje, valor) => onNewAlert(
            pool.id,
            parametro,
            nivel,
            mensaje,
          ),
          onInventarioBajo: (quimicoNombre, pct) => onInventarioBajo(
            pool.id,
            quimicoNombre,
            pct,
          ),
        );
      }
    } catch (e) {
      debugPrint('RealtimeService.subscribeToAllPools error: $e');
    }
  }

  Future<void> unsubscribeFromPool(String poolId) async {
    try {
      final keys = _channels.keys.where((key) => key.startsWith('pool-$poolId-')).toList();
      for (final key in keys) {
        _channels[key]?.unsubscribe();
        _channels.remove(key);
      }
    } catch (e) {
      debugPrint('RealtimeService.unsubscribeFromPool error: $e');
    }
  }

  Future<void> unsubscribeAll() async {
    try {
      for (final channel in _channels.values) {
        channel.unsubscribe();
      }
      _channels.clear();
    } catch (e) {
      debugPrint('RealtimeService.unsubscribeAll error: $e');
    }
  }

  void _attachReadingChannel({
    required RealtimeChannel channel,
    required String poolId,
    required String poolNombre,
    required void Function(String parametro, double valor, String status)
        onNewReading,
  }) {
    final filter = PostgresChangeFilter(
      column: 'pool_id',
      value: poolId,
      type: PostgresChangeFilterType.eq,
    );

    void handleChange(String parametro, PostgresChangePayload payload) {
      final record = payload.newRecord;
      final valor = (record['valor'] as num?)?.toDouble() ?? 0.0;
      final status = (record['status'] as String?) ?? 'desconocido';
      final zona = _extractZona(record);
      onNewReading(parametro, valor, status);

      if (status != 'optimo') {
        NotificationService.instance.showAlerta(
          poolNombre: poolNombre,
          poolId: poolId,
          zona: zona,
          parametro: parametro,
          valor: valor,
          nivel: status == 'critico' ? 'critico' : 'alerta',
          mensaje: 'Valor fuera de rango',
        );
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableReadingsPh,
      filter: filter,
      callback: (payload) => handleChange('ph', payload),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableReadingsCloro,
      filter: filter,
      callback: (payload) => handleChange('cloro', payload),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableReadingsAlcalinidad,
      filter: filter,
      callback: (payload) => handleChange('alcalinidad', payload),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableReadingsTurbidez,
      filter: filter,
      callback: (payload) => handleChange('turbidez', payload),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableReadingsTemperatura,
      filter: filter,
      callback: (payload) {
        final record = payload.newRecord;
        final tipo = (record['tipo'] as String?)?.trim().toLowerCase();
        final parametro = tipo == 'ambiente' ? 'temperatura_ambiente' : 'temperatura';
        handleChange(parametro, payload);
      },
    );
  }

  void _attachAlertChannel({
    required RealtimeChannel channel,
    required String poolId,
    required String poolNombre,
    required void Function(String parametro, String nivel, String mensaje,
            double valor)
        onNewAlert,
    required void Function(String quimicoNombre, double pct) onInventarioBajo,
  }) {
    final filter = PostgresChangeFilter(
      column: 'pool_id',
      value: poolId,
      type: PostgresChangeFilterType.eq,
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableAlerts,
      filter: filter,
      callback: (payload) {
        final record = payload.newRecord;
        final zona = _extractZona(record);
        final parametro = (record['parametro'] as String?) ?? 'alerta';
        final nivel = (record['nivel'] as String?) ?? 'alerta';
        final mensaje = (record['mensaje'] as String?) ?? 'Alerta detectada';
        final valor = (record['valor_detectado'] as num?)?.toDouble() ?? 0.0;
        onNewAlert(parametro, nivel, mensaje, valor);
        NotificationService.instance.showAlerta(
          poolNombre: poolNombre,
          poolId: poolId,
          zona: zona,
          parametro: parametro,
          valor: valor,
          nivel: nivel,
          mensaje: mensaje,
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chemical_inventory',
      filter: filter,
      callback: (payload) {
        final record = payload.newRecord;
        final zona = _extractZona(record);
        final quimicoNombre =
            (record['quimico_nombre'] as String?) ?? 'Químico';
        final nivelActual = (record['nivel_actual_litros'] as num?)?.toDouble() ?? 0.0;
        final capacidadMax = (record['capacidad_max_litros'] as num?)?.toDouble() ?? 0.0;
        final pct = capacidadMax <= 0 ? 0.0 : (nivelActual / capacidadMax) * 100;
        if (pct <= 20) {
          onInventarioBajo(quimicoNombre, pct);
          NotificationService.instance.showInventarioBajo(
            poolNombre: poolNombre,
            poolId: poolId,
            zona: zona,
            quimicoNombre: quimicoNombre,
            pct: pct,
          );
        }
      },
    );
  }

  String _extractZona(Map<String, dynamic> record) {
    final raw = (record['zona'] ?? record['ubicacion'] ?? record['area']) as String?;
    final zona = raw?.trim();
    if (zona == null || zona.isEmpty) return 'Zona general';
    return zona;
  }

  String _key(String poolId, String suffix) => 'pool-$poolId-$suffix';
}

