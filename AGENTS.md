## Flutter SDK
- Path: ~/flutter-sdk/bin/flutter
- Run app: `~/flutter-sdk/bin/flutter run`
- Get dependencies: `~/flutter-sdk/bin/flutter pub get`

## Android SDK Configuration
- compileSdk: 35 (Android 15)
- minSdk: 23 (Android 6.0 - required by AndroidX)
- targetSdk: 35 (required by Google Play)
- Java/Kotlin: VERSION_17

## Design Patterns

### Strings & i18n
- All user-facing strings must be defined in `lib/constants/strings.dart` (AppStrings class)
- Never hardcode strings in widgets - import and use `AppStrings.stringName`
- This enables future localization support

### Theme
- Theme constants are in `lib/constants/theme.dart` (AppTheme class)
- Use `Theme.of(context)` for colors, text styles, etc.
