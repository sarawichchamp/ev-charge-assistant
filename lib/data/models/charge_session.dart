class ChargeSession {
  const ChargeSession({
    this.id,
    required this.createdAt,
    required this.currentSoc,
    required this.targetSoc,
    required this.odometerKm,
    required this.energyRequiredKwh,
    required this.pricePerKwh,
    required this.startTime,
    required this.finishTime,
  });

  final int? id;
  final DateTime createdAt;
  final int currentSoc;
  final int targetSoc;
  final int odometerKm;
  final double energyRequiredKwh;
  final double pricePerKwh;
  final DateTime startTime;
  final DateTime finishTime;

  double get totalCost => energyRequiredKwh * pricePerKwh;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'current_soc': currentSoc,
      'target_soc': targetSoc,
      'odometer_km': odometerKm,
      'energy_required_kwh': energyRequiredKwh,
      'price_per_kwh': pricePerKwh,
      'start_time': startTime.toIso8601String(),
      'finish_time': finishTime.toIso8601String(),
    };
  }

  factory ChargeSession.fromMap(Map<String, Object?> map) {
    return ChargeSession(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      currentSoc: map['current_soc'] as int,
      targetSoc: map['target_soc'] as int,
      odometerKm: map['odometer_km'] as int,
      energyRequiredKwh: (map['energy_required_kwh'] as num).toDouble(),
      pricePerKwh: (map['price_per_kwh'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time'] as String),
      finishTime: DateTime.parse(map['finish_time'] as String),
    );
  }
}
