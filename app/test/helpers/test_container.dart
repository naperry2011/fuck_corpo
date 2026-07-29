import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/state/providers.dart';

import 'fake_clock.dart';
import 'memory_store.dart';

/// A container wired to an in-memory store and a hand-advanced clock.
ProviderContainer makeTestContainer({
  required MemoryStore store,
  required FakeClock clock,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(clock.call),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
