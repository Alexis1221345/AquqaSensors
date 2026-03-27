class AppConstants {
  AppConstants._();

  // ── Rangos óptimos de la alberca ──────────────────────────────

  static const double phMin = 7.2;
  static const double phMax = 7.8;
  static const double phAbsMin = 6.0;
  static const double phAbsMax = 9.0;

  static const double cloroMin = 1.0;
  static const double cloroMax = 3.0;
  static const double cloroAbsMin = 0.0;
  static const double cloroAbsMax = 5.0;

  static const double tempMin = 26.0;
  static const double tempMax = 30.0;
  static const double tempAbsMin = 15.0;
  static const double tempAbsMax = 40.0;

  static const double turbidezMin = 0.0;
  static const double turbidezMax = 1.0;
  static const double turbidezAbsMax = 5.0;

  static const double alcalinidadMin = 80.0;
  static const double alcalinidadMax = 150.0;
  static const double alcalinidadAbsMin = 60.0;
  static const double alcalinidadAbsMax = 200.0;

  // ── Rutas de navegación ───────────────────────────────────────

  static const String routeLogin       = '/login';
  static const String routeRegister    = '/register';
  static const String routeVerifyEmail = '/verify-email';
  static const String routeHome        = '/';
  static const String routeReports     = '/reports';
  static const String routeAccount     = '/account';
  static const String routeEditProfile = '/account/edit';
  static const String routePool        = '/pool';

  // ── Supabase — tablas ─────────────────────────────────────────

  static const String tableReadingsPh          = 'readings_ph';
  static const String tableReadingsCloro       = 'readings_cloro';
  static const String tableReadingsTemperatura = 'readings_temperatura';
  static const String tableReadingsTurbidez    = 'readings_turbidez';
  static const String tableReadingsAlcalinidad = 'readings_alcalinidad';
  static const String tableProfiles            = 'profiles';
  static const String tablePools               = 'pools';
  static const String tableChemicalDoses       = 'chemical_doses';
  static const String tableAlerts              = 'alerts';

  // ── Supabase — buckets ────────────────────────────────────────

  static const String bucketImages  = 'pool-images';
  static const String bucketAvatars = 'avatars';

  // ── ESP32 ─────────────────────────────────────────────────────

  static const String esp32DefaultIp         = '192.168.1.100';
  static const int    esp32Port              = 80;
  static const String esp32EndpointReadings  = '/sensors';
  static const String esp32EndpointStatus    = '/status';
  static const String esp32EndpointProvisionWifi = '/provision-wifi';
  static const String esp32BleServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String esp32BleCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  // ── UI ────────────────────────────────────────────────────────

  static const double cardRadius      = 16.0;
  static const double buttonRadius    = 12.0;
  static const double defaultPadding  = 16.0;
}