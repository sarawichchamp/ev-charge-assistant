enum AutomationMode {
  textRecognition,
  trainingFallback,
}

class AutomationPoint {
  const AutomationPoint({
    required this.key,
    required this.label,
    required this.x,
    required this.y,
  });

  final String key;
  final String label;
  final double x;
  final double y;

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'label': label,
      'x': x,
      'y': y,
    };
  }

  factory AutomationPoint.fromMap(Map<String, Object?> map) {
    return AutomationPoint(
      key: map['key'] as String,
      label: map['label'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

class AutomationMapping {
  const AutomationMapping({
    required this.mode,
    required this.points,
  });

  final AutomationMode mode;
  final List<AutomationPoint> points;

  AutomationMapping copyWith({
    AutomationMode? mode,
    List<AutomationPoint>? points,
  }) {
    return AutomationMapping(
      mode: mode ?? this.mode,
      points: points ?? this.points,
    );
  }
}
