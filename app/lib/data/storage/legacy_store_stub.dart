import 'legacy_store.dart';

/// Android, iOS and desktop have no browser `localStorage` to bridge from, so
/// there is nothing to open. See `docs/migration/storage_schema_v1.md`: the only
/// supported web-to-mobile transfer is a user-driven export/import.
LegacyStore? openLegacyStore() => null;
