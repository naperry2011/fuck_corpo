import 'package:flutter/foundation.dart';

/// User settings. Parsed field by field against defaults, so a partial payload
/// can never leave a field undefined (BUG-007).
@immutable
class AppSettings {
  const AppSettings({
    required this.theme,
    required this.currency,
    required this.timezone,
    required this.industry,
    required this.region,
    required this.soundEnabled,
  });

  static const AppSettings initial = AppSettings(
    theme: 'dark',
    currency: 'USD',
    timezone: '',
    industry: '',
    region: '',
    soundEnabled: true,
  );

  final String theme;
  final String currency;

  /// Collected by onboarding and never read. Retained so existing exports still
  /// import cleanly; do not build new behavior on it.
  @Deprecated('Carried for import compatibility only. Not used anywhere.')
  final String timezone;

  final String industry;

  /// Persisted under the legacy `state` key.
  final String region;

  final bool soundEnabled;

  AppSettings copyWith({
    String? theme,
    String? currency,
    String? timezone,
    String? industry,
    String? region,
    bool? soundEnabled,
  }) => AppSettings(
    theme: theme ?? this.theme,
    currency: currency ?? this.currency,
    // ignore: deprecated_member_use_from_same_package
    timezone: timezone ?? this.timezone,
    industry: industry ?? this.industry,
    region: region ?? this.region,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'theme': theme,
    'currency': currency,
    // ignore: deprecated_member_use_from_same_package
    'timezone': timezone,
    'industry': industry,
    'state': region,
    'soundEnabled': soundEnabled,
  };

  factory AppSettings.fromJson(Object? json) {
    if (json is! Map) return initial;
    String str(String key, String fallback) =>
        json[key] is String ? json[key] as String : fallback;
    return AppSettings(
      theme: str('theme', initial.theme),
      currency: str('currency', initial.currency),
      // ignore: deprecated_member_use_from_same_package
      timezone: str('timezone', initial.timezone),
      industry: str('industry', initial.industry),
      region: str('state', initial.region),
      // React treats any value other than `false` as enabled.
      soundEnabled: json['soundEnabled'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.currency == currency &&
      // ignore: deprecated_member_use_from_same_package
      other.timezone == timezone &&
      other.industry == industry &&
      other.region == region &&
      other.soundEnabled == soundEnabled;

  @override
  int get hashCode => Object.hash(
    theme,
    currency,
    // ignore: deprecated_member_use_from_same_package
    timezone,
    industry,
    region,
    soundEnabled,
  );
}
