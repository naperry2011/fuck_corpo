# Self-hosted brand fonts

Fetched from the upstream `google/fonts` repository (`main` branch). All three
are under the SIL Open Font License 1.1; the license text ships next to each
binary.

| File | Upstream path | Axis range | License |
|---|---|---|---|
| `PlayfairDisplay-Variable.ttf` | `ofl/playfairdisplay/PlayfairDisplay[wght].ttf` | wght 400-900 | `OFL-PlayfairDisplay.txt` |
| `WorkSans-Variable.ttf` | `ofl/worksans/WorkSans[wght].ttf` | wght 100-900 | `OFL-WorkSans.txt` |
| `RobotoMono-Variable.ttf` | `ofl/robotomono/RobotoMono[wght].ttf` | wght 100-700 | `OFL-RobotoMono.txt` |

These are the variable fonts, not static instances: upstream no longer ships a
`static/` directory for these families. `pubspec.yaml` declares each weight the
theme asks for against the same file, which is how Flutter instantiates a
`wght` axis.

Self-hosting means the app never requests fonts.googleapis.com at runtime, so
typography survives offline and the PWA has no third-party font dependency.

Refresh with `app/tool/fetch_fonts.sh` (run from `app/`), then
`flutter test test/core/theme/fonts_test.dart`.
