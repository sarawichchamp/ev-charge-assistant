import 'package:ev_charge_assistant/services/charge_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates energy and schedule correctly', () {
    const calculator = ChargeCalculator();
    final finishTime = DateTime(2026, 1, 1, 8, 0);

    final result = calculator.calculate(
      batteryCapacityKwh: 66.8,
      chargePowerKw: 7.0,
      currentSoc: 17,
      targetSoc: 80,
      finishTime: finishTime,
    );

    expect(result.energyRequiredKwh, closeTo(42.084, 0.001));
    expect(result.chargingHours, closeTo(6.012, 0.001));
    expect(result.startTime, DateTime(2026, 1, 1, 1, 59));
  });
}
