import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'break_record.dart';
import 'running_timer.dart';
import 'salary.dart';

/// Aggregate root and the persisted schema. See
/// `docs/migration/storage_schema_v1.md`.
@immutable
class AppState {
  const AppState({
    required this.schemaVersion,
    required this.salary,
    required this.breaks,
    required this.settings,
    required this.achievements,
    required this.onboarded,
    this.runningTimer,
  });

  /// Current storage schema version. v0 is the unversioned React payload.
  static const int currentSchemaVersion = 1;

  static const AppState initial = AppState(
    schemaVersion: currentSchemaVersion,
    salary: Salary.initial,
    breaks: <BreakRecord>[],
    settings: AppSettings.initial,
    achievements: <String>[],
    onboarded: false,
  );

  final int schemaVersion;
  final Salary salary;
  final List<BreakRecord> breaks;
  final AppSettings settings;
  final List<String> achievements;
  final bool onboarded;
  final RunningTimer? runningTimer;

  AppState copyWith({
    Salary? salary,
    List<BreakRecord>? breaks,
    AppSettings? settings,
    List<String>? achievements,
    bool? onboarded,
    RunningTimer? runningTimer,
    bool clearRunningTimer = false,
  }) => AppState(
    schemaVersion: schemaVersion,
    salary: salary ?? this.salary,
    breaks: breaks ?? this.breaks,
    settings: settings ?? this.settings,
    achievements: achievements ?? this.achievements,
    onboarded: onboarded ?? this.onboarded,
    runningTimer: clearRunningTimer
        ? null
        : (runningTimer ?? this.runningTimer),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'salary': salary.toJson(),
    'breaks': breaks.map((b) => b.toJson()).toList(),
    'settings': settings.toJson(),
    'achievements': achievements,
    'onboarded': onboarded,
    'runningTimer': runningTimer?.toJson(),
  };

  /// Parses a v0 (unversioned React) or v1 payload.
  ///
  /// Structurally invalid payloads throw so the caller can surface an error and
  /// keep existing state, instead of silently replacing it (BUG-004). Individual
  /// malformed break rows are dropped rather than failing the whole load.
  factory AppState.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Payload is not a JSON object');
    }
    final Object? rawBreaks = json['breaks'];
    if (rawBreaks != null && rawBreaks is! List) {
      throw const FormatException('"breaks" must be a list');
    }
    final Object? rawAchievements = json['achievements'];
    if (rawAchievements != null && rawAchievements is! List) {
      throw const FormatException('"achievements" must be a list');
    }

    final List<BreakRecord> breaks = <BreakRecord>[
      for (final Object? entry in (rawBreaks as List? ?? const <Object?>[]))
        if (BreakRecord.tryFromJson(entry) case final BreakRecord record)
          record,
    ];

    return AppState(
      schemaVersion: currentSchemaVersion,
      salary: Salary.fromJson(json['salary']),
      breaks: breaks,
      settings: AppSettings.fromJson(json['settings']),
      achievements: <String>[
        for (final Object? id
            in (rawAchievements as List? ?? const <Object?>[]))
          if (id is String) id,
      ],
      onboarded: json['onboarded'] == true,
      runningTimer: RunningTimer.fromJson(json['runningTimer']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppState &&
      other.schemaVersion == schemaVersion &&
      other.salary == salary &&
      listEquals(other.breaks, breaks) &&
      other.settings == settings &&
      listEquals(other.achievements, achievements) &&
      other.onboarded == onboarded &&
      other.runningTimer == runningTimer;

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    salary,
    Object.hashAll(breaks),
    settings,
    Object.hashAll(achievements),
    onboarded,
    runningTimer,
  );
}
