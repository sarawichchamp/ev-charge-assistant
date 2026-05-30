class ChargeCalculation {
  const ChargeCalculation({
    required this.energyRequiredKwh,
    required this.chargingHours,
    required this.startTime,
    required this.finishTime,
  });

  final double energyRequiredKwh;
  final double chargingHours;
  final DateTime startTime;
  final DateTime finishTime;
}

class ChargeCalculator {
  const ChargeCalculator();

  ChargeCalculation calculate({
    required double batteryCapacityKwh,
    required double chargePowerKw,
    required int currentSoc,
    required int targetSoc,
    required DateTime finishTime,
  }) {
    final boundedTarget = targetSoc.clamp(currentSoc, 100);
    final energyRequired = batteryCapacityKwh * (boundedTarget - currentSoc) / 100;
    final chargingHours = chargePowerKw == 0 ? 0.0 : energyRequired / chargePowerKw;
    final durationMinutes = (chargingHours * 60).round();
    final startTime = finishTime.subtract(Duration(minutes: durationMinutes));

    return ChargeCalculation(
      energyRequiredKwh: energyRequired,
      chargingHours: chargingHours,
      startTime: startTime,
      finishTime: finishTime,
    );
  }
}
