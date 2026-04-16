import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'aquasensors_alerts',
    'Alertas AquaSensors',
    description: 'Alertas, inventarios y dosis recomendadas de AquaSensors',
    importance: Importance.high,
    playSound: true,
  );

  final Map<String, DateTime> _lastShown = {};
  bool _initialized = false;
  bool _permissionGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_channel);

      // Solicita permisos en Android 13+ y iOS/macOS.
      _permissionGranted = await requestPermissions();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final iosImpl =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final macImpl =
          _plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();

      final androidGranted = await androidImpl?.requestNotificationsPermission();
      final iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final macGranted = await macImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _permissionGranted =
          (androidGranted ?? true) && (iosGranted ?? true) && (macGranted ?? true);
      return _permissionGranted;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions error: $e');
      return false;
    }
  }

  Future<void> showAlerta({
    required String poolNombre,
    required String poolId,
    required String zona,
    required String parametro,
    required double valor,
    required String nivel,
    required String mensaje,
  }) async {
    final zonaLabel = _normalizeZona(zona);
    await _showGuarded(
      key: 'alert|$poolId|$zonaLabel|$parametro',
      id: _notificationId(poolId, '$zonaLabel|$parametro'),
      poolId: poolId,
      title: nivel == 'critico'
          ? '🚨 $poolNombre | $zonaLabel'
          : '⚠ $poolNombre | $zonaLabel',
      body: 'Alerta ${nivel.toUpperCase()}: $parametro en ${_fmt(valor)}\n$mensaje',
      color: nivel == 'critico' ? const Color(0xFFD32F2F) : null,
      category: 'alerta',
      subText: 'Alberca: $poolNombre · Zona: $zonaLabel',
    );
  }

  Future<void> showInventarioBajo({
    required String poolNombre,
    required String poolId,
    required String zona,
    required String quimicoNombre,
    required double pct,
  }) async {
    final zonaLabel = _normalizeZona(zona);
    await _showGuarded(
      key: 'inventory|$poolId|$zonaLabel|$quimicoNombre',
      id: _notificationId(poolId, '$zonaLabel|$quimicoNombre'),
      poolId: poolId,
      title: '🧪 $poolNombre | $zonaLabel',
      body: 'Inventario bajo: $quimicoNombre al ${_fmt(pct)}%\nReabastecer',
      category: 'inventario',
      subText: 'Alberca: $poolNombre · Zona: $zonaLabel',
    );
  }

  Future<void> showDosisRecomendada({
    required String poolNombre,
    required String poolId,
    String? zona,
    required String quimico,
    required double cantidadMl,
  }) async {
    final zonaLabel = _normalizeZona(zona);
    await _showNow(
      id: _notificationId(poolId, '$zonaLabel|$quimico') + 7,
      poolId: poolId,
      title: '💊 $poolNombre | $zonaLabel',
      body: 'Dosis recomendada: aplicar ${_fmt(cantidadMl)} ml de $quimico',
      category: 'dosis',
      subText: 'Alberca: $poolNombre · Zona: $zonaLabel',
    );
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      _lastShown.clear();
    } catch (e) {
      debugPrint('NotificationService.cancelAll error: $e');
    }
  }

  int _notificationId(String poolId, String key) =>
      (poolId.hashCode + key.hashCode).abs();

  Future<void> _showGuarded({
    required String key,
    required int id,
    required String poolId,
    required String title,
    required String body,
    String? category,
    Color? color,
    String? subText,
  }) async {
    final now = DateTime.now();
    final last = _lastShown[key];
    if (last != null && now.difference(last) < const Duration(minutes: 5)) {
      return;
    }
    _lastShown[key] = now;
    await _showNow(
      id: id,
      poolId: poolId,
      title: title,
      body: body,
      category: category,
      color: color,
      subText: subText,
    );
  }

  Future<void> _showNow({
    required int id,
    required String poolId,
    required String title,
    required String body,
    String? category,
    Color? color,
    String? subText,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_permissionGranted) {
        _permissionGranted = await requestPermissions();
      }
      if (!_permissionGranted) {
        return;
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: color,
          groupKey: 'pool_$poolId',
          subText: subText,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: category,
      );
    } catch (e) {
      debugPrint('NotificationService.show error: $e');
    }
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _normalizeZona(String? zona) {
    final cleaned = zona?.trim();
    if (cleaned == null || cleaned.isEmpty) return 'Zona general';
    return cleaned;
  }
}


