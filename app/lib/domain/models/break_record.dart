import 'package:flutter/foundation.dart';

import 'break_category.dart';

/// One logged break. `durationMs` and the ISO `timestamp` match the React shape.
@immutable
class BreakRecord {
  const BreakRecord({
    required this.id,
    required this.category,
    required this.durationMs,
    required this.timestamp,
  });

  final String id;
  final BreakCategory category;
  final int durationMs;
  final DateTime timestamp;

  Duration get duration => Duration(milliseconds: durationMs);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'category': category.wire,
    'duration': durationMs,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Strict parse. Returns null for anything that is not a usable record, so
  /// callers can drop bad rows instead of failing the whole import (BUG-004).
  static BreakRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final Object? id = json['id'];
    final Object? duration = json['duration'];
    final Object? timestamp = json['timestamp'];
    if (id is! String || id.isEmpty) return null;
    if (duration is! num) return null;
    if (timestamp is! String) return null;
    final DateTime? parsed = DateTime.tryParse(timestamp);
    if (parsed == null) return null;
    return BreakRecord(
      id: id,
      category: BreakCategory.fromWire(json['category']),
      durationMs: duration.round(),
      timestamp: parsed,
    );
  }

  factory BreakRecord.fromJson(Object? json) {
    final BreakRecord? record = tryFromJson(json);
    if (record == null) {
      throw const FormatException('Invalid break record');
    }
    return record;
  }

  @override
  bool operator ==(Object other) =>
      other is BreakRecord &&
      other.id == id &&
      other.category == category &&
      other.durationMs == durationMs &&
      other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(id, category, durationMs, timestamp);
}
