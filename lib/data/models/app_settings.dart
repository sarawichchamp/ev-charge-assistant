import 'package:flutter/material.dart';

import '../../core/constants/app_defaults.dart';

class AppSettings {
  const AppSettings({
    required this.batteryCapacityKwh,
    required this.chargePowerKw,
    required this.pricePerKwh,
    required this.defaultTargetSoc,
    required this.themeMode,
  });

  final double batteryCapacityKwh;
  final double chargePowerKw;
  final double pricePerKwh;
  final int defaultTargetSoc;
  final ThemeMode themeMode;

  factory AppSettings.defaults() {
    return const AppSettings(
      batteryCapacityKwh: AppDefaults.batteryCapacityKwh,
      chargePowerKw: AppDefaults.chargePowerKw,
      pricePerKwh: AppDefaults.pricePerKwh,
      defaultTargetSoc: AppDefaults.defaultTargetSoc,
      themeMode: ThemeMode.system,
    );
  }

  AppSettings copyWith({
    double? batteryCapacityKwh,
    double? chargePowerKw,
    double? pricePerKwh,
    int? defaultTargetSoc,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      batteryCapacityKwh: batteryCapacityKwh ?? this.batteryCapacityKwh,
      chargePowerKw: chargePowerKw ?? this.chargePowerKw,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      defaultTargetSoc: defaultTargetSoc ?? this.defaultTargetSoc,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'battery_capacity_kwh': batteryCapacityKwh,
      'charge_power_kw': chargePowerKw,
      'price_per_kwh': pricePerKwh,
      'default_target_soc': defaultTargetSoc,
      'theme_mode': themeMode.name,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      batteryCapacityKwh: (map['battery_capacity_kwh'] as num?)?.toDouble() ??
          AppDefaults.batteryCapacityKwh,
      chargePowerKw:
          (map['charge_power_kw'] as num?)?.toDouble() ?? AppDefaults.chargePowerKw,
      pricePerKwh:
          (map['price_per_kwh'] as num?)?.toDouble() ?? AppDefaults.pricePerKwh,
      defaultTargetSoc:
          (map['default_target_soc'] as num?)?.toInt() ?? AppDefaults.defaultTargetSoc,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == map['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
    );
  }
}
