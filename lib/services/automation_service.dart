import 'dart:async';

import 'package:flutter/services.dart';

class AutomationReadResult {
  const AutomationReadResult({
    required this.success,
    this.currentSoc,
    this.odometerKm,
    this.message,
  });

  final bool success;
  final int? currentSoc;
  final int? odometerKm;
  final String? message;
}

class AutomationFillRequest {
  const AutomationFillRequest({
    required this.odometerKm,
    required this.energyKwh,
    required this.pricePerKwh,
    required this.targetSoc,
    required this.currentSoc,
  });

  final int odometerKm;
  final double energyKwh;
  final double pricePerKwh;
  final int targetSoc;
  final int currentSoc;

  Map<String, Object?> toMap() {
    return {
      'odometerKm': odometerKm,
      'energyKwh': energyKwh,
      'pricePerKwh': pricePerKwh,
      'targetSoc': targetSoc,
      'currentSoc': currentSoc,
    };
  }
}

class AutomationService {
  static const _methodChannel = MethodChannel('ev_charge_assistant/methods');
  static const _eventChannel = EventChannel('ev_charge_assistant/events');

  Stream<dynamic>? _eventStream;

  Future<void> initialize() async {
    _eventStream ??= _eventChannel.receiveBroadcastStream();
  }

  Stream<dynamic> get events => _eventStream ?? const Stream.empty();

  Future<bool> ensurePermissions() async {
    final result =
        await _methodChannel.invokeMethod<bool>('ensurePermissions');
    return result ?? false;
  }

  Future<void> launchDeepal() async {
    await _methodChannel.invokeMethod('launchDeepal');
  }

  Future<void> launchFuelio() async {
    await _methodChannel.invokeMethod('launchFuelio');
  }

  Future<AutomationReadResult> readSocAndOdometer() async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>(
      'readSocAndOdometer',
    );
    return AutomationReadResult(
      success: result?['success'] as bool? ?? false,
      currentSoc: (result?['currentSoc'] as num?)?.toInt(),
      odometerKm: (result?['odometerKm'] as num?)?.toInt(),
      message: result?['message'] as String?,
    );
  }

  Future<bool> fillFuelio(AutomationFillRequest request) async {
    final result = await _methodChannel.invokeMethod<bool>(
      'fillFuelio',
      request.toMap(),
    );
    return result ?? false;
  }

  Future<bool> saveFuelioEntry() async {
    final result = await _methodChannel.invokeMethod<bool>('saveFuelioEntry');
    return result ?? false;
  }

  Future<void> openTrainingOverlay(String mappingKey) async {
    await _methodChannel.invokeMethod('openTrainingOverlay', {
      'mappingKey': mappingKey,
    });
  }

  Future<void> saveMappingPoint({
    required String mappingKey,
    required String label,
    required double x,
    required double y,
  }) async {
    await _methodChannel.invokeMethod('saveMappingPoint', {
      'mappingKey': mappingKey,
      'label': label,
      'x': x,
      'y': y,
    });
  }

  Future<void> saveAutomationMode(String mode) async {
    await _methodChannel.invokeMethod('saveAutomationMode', {
      'mode': mode,
    });
  }

  Future<void> openDeepalForSchedule() async {
    await _methodChannel.invokeMethod('openDeepalForSchedule');
  }
}
