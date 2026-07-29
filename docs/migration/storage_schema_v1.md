# Storage schema v1

Implemented by `app/lib/domain/models/app_state.dart` and
`app/lib/data/app_repository.dart`.

## Keys

| Key | Owner | Contents |
|---|---|---|
| `fuckcorpo_data` | React | v0 payload. Flutter reads it only during the v0 bridge and never writes it |
| `fuckcorpo_state_v1` | Flutter | v1 payload described below. On web, `shared_preferences` stores this under a `flutter.` prefix |

Keeping the keys separate is what makes rollback to React lossless. It also
means the two apps diverge after the first Flutter load, which is an accepted
tradeoff recorded in plan Section 8.3.

## v1 payload

```json
{
  "schemaVersion": 1,
  "salary": { "amount": 0, "type": "annual", "currency": "USD" },
  "breaks": [
    {
      "id": "uuid",
      "category": "Bathroom",
      "duration": 60000,
      "timestamp": "2026-03-04T09:00:00.000"
    }
  ],
  "settings": {
    "theme": "dark",
    "currency": "USD",
    "timezone": "",
    "industry": "",
    "state": "",
    "soundEnabled": true
  },
  "achievements": ["first_flush"],
  "onboarded": false,
  "runningTimer": null
}
```

### Field notes

- `schemaVersion` is new in v1. A payload without it is treated as v0 and read
  with the same parser.
- `breaks[].duration` is milliseconds. `breaks[].timestamp` is an ISO 8601
  string.
- `breaks[].category` is one of the five `BreakCategory` wire values:
  `Bathroom`, `Smoke Break`, `Mental Health Moment`, `Coffee Break`, `Other`.
  Unknown values resolve to `Other`.
- `salary.type` is one of `annual`, `hourly`, `monthly`, `weekly`. Unknown
  values resolve to `annual`, matching the React `default` branch.
- `settings.state` is the user's region. The legacy key name is retained so old
  exports import cleanly.
- `settings.timezone` is deprecated. It is carried for import compatibility and
  read by nothing.
- `settings.soundEnabled` is true unless the stored value is exactly `false`,
  matching the React `!== false` check.
- `runningTimer` is new in v1: `{ "startedAt": "<ISO>", "category": "<wire>" }`
  or `null`. Elapsed time is always recomputed from the wall clock.

## Parsing rules

`load` is forgiving, `import` is strict.

| Input | `load()` | `importJson()` |
|---|---|---|
| Key absent | defaults | n/a |
| Unparseable JSON | defaults | throws `FormatException` |
| Not a JSON object | defaults | throws `FormatException` |
| `breaks` or `achievements` not a list | defaults | throws `FormatException` |
| A single malformed break row | row dropped, rest kept | row dropped, rest kept |
| Missing `salary` or `settings` fields | per-field defaults | per-field defaults |

A rejected import leaves the stored state untouched.

## The v0 bridge

Implemented by `app/lib/data/migrations/v0_localstorage_to_v1.dart`, run in
`main.dart` before `runApp`. Covered by
`app/test/data/migrations/v0_localstorage_to_v1_test.dart` (13 tests).

`shared_preferences` namespaces every key under `flutter.` on web, so it cannot
see the React key. `LegacyStore` is the narrow escape hatch that reads raw
`localStorage`, resolved by conditional import: `WebLegacyStore` on web,
`null` everywhere else.

### Extra keys

| Key | Owner | Contents |
|---|---|---|
| `flutter.fuckcorpo_migrated_from_v0` | Flutter | `"true"` once the bridge has run on this profile, successfully or not |
| `fuckcorpo_data_backup` | Flutter, written once | The raw React payload, copied verbatim, only when it failed to parse |

Note the prefix asymmetry: the marker goes through `shared_preferences` and so
is stored as `flutter.fuckcorpo_migrated_from_v0`, while the backup is written
through the raw legacy store and so is unprefixed, sitting next to
`fuckcorpo_data`.

### Decision order

1. A v1 payload already exists at `fuckcorpo_state_v1` and is non-empty. Stop,
   never overwrite. (`skippedExistingV1`)
2. The marker is `"true"`. Stop. This holds even if the v1 key was later cleared,
   so "Clear All Data" is not silently undone by a re-import.
   (`skippedAlreadyMigrated`)
3. Not on web, or no `fuckcorpo_data` key, or it is empty. Start from defaults.
   (`skippedNoLegacyData`)
4. The payload parses. Write it to the v1 key, set the marker. (`migrated`)
5. The payload does not parse. Copy it to `fuckcorpo_data_backup`, set the
   marker, boot to defaults. (`failedBackedUp`)

### Guarantees

- `fuckcorpo_data` is **read only**. Flutter never writes or deletes it, so
  React keeps working and a rollback loses nothing.
- Migration runs at most once per browser profile.
- A corrupt payload never bricks the app and is never discarded.
- Partial payloads resolve field by field against defaults, so no field is ever
  left undefined.

### Consequences

After the first Flutter load the two apps diverge: data added in React is not
picked up by Flutter, and vice versa. This is deliberate (deviation D-104) and
must appear in the release note.

There is no automatic path from web to mobile. Android and iOS cannot read
browser storage; the only supported transfer is export then import, and the
importer accepts both v0 and v1 payloads.

### Still missing

The one-time in-app notice for the `failedBackedUp` case, described in plan
Section 8.3, is not implemented. That failure is currently silent to the user.
