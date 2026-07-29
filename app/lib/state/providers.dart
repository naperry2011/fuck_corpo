import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';
import '../data/storage/key_value_store.dart';
import '../domain/calculations.dart';
import '../domain/models/app_state.dart';
import 'app_controller.dart';

/// The concrete store, injected at boot. Overridden in `main.dart` with the
/// warmed `SharedPrefsStore`, and in tests with an in-memory map.
final Provider<KeyValueStore> keyValueStoreProvider = Provider<KeyValueStore>(
  (Ref ref) => throw UnimplementedError(
    'keyValueStoreProvider must be overridden during boot',
  ),
);

final Provider<AppRepository> appRepositoryProvider = Provider<AppRepository>(
  (Ref ref) => AppRepository(ref.watch(keyValueStoreProvider)),
);

/// The wall clock. Injected so the timer can be tested without waiting.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final NotifierProvider<AppController, AppState> appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

/// Earnings per working minute, derived from the salary exactly as the React
/// context derived it.
final Provider<double> perMinuteRateProvider = Provider<double>((Ref ref) {
  final salary = ref.watch(appControllerProvider.select((s) => s.salary));
  return salaryToPerMinute(salary.amount, salary.type);
});

/// The currency every money figure is formatted in.
final Provider<String> currencyProvider = Provider<String>(
  (Ref ref) =>
      ref.watch(appControllerProvider.select((s) => s.settings.currency)),
);
