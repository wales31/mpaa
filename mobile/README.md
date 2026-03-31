# MPAA Mobile Foundation

This folder contains the Week 1 Flutter foundation scaffold.

## 1) Create Android + iOS platform projects

From the `mobile/` directory run:

```bash
flutter create . --platforms=android,ios
```

This generates native projects under `android/` and `ios/` in this folder.

## 2) Environment strategy

Environment config is loaded from `--dart-define` values in `AppConfig`:

- `APP_ENV` (`dev`, `stage`, `prod`)
- `API_BASE_URL`
- `FIREBASE_PROJECT_ID`

Example commands:

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=https://api.dev.example.com \
  --dart-define=FIREBASE_PROJECT_ID=mpaa-dev
```

```bash
flutter run \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=FIREBASE_PROJECT_ID=mpaa-prod
```


## 3) Link this Flutter app to the same Firebase project/database used by web

The web app in this repo uses `firebase-applet-config.json` with:

- project: `gen-lang-client-0470901675`
- web app id: `1:907517612385:web:3a0aba9931ecf8fd3cb520`
- Firestore database id: `ai-studio-87ceaf75-f592-4224-be82-5e9fe92985ab`

To connect mobile to the same backend:

1. In Firebase Console, open project **gen-lang-client-0470901675**.
2. Add **Android** and/or **iOS** app(s) for this project (use your package/bundle ids).
3. From `mobile/`, run:

```bash
flutterfire configure --project=gen-lang-client-0470901675
```

This generates `lib/firebase_options.dart` and platform config files.

4. Update `bootstrap.dart` initialization to use generated options:

```dart
import 'package:mpaa_mobile/firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

5. If you need the same **named Firestore database** as web (`ai-studio-87ceaf75-f592-4224-be82-5e9fe92985ab`), use:

```dart
final firestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'ai-studio-87ceaf75-f592-4224-be82-5e9fe92985ab',
);
```

6. Ensure Firebase Auth and Firestore rules allow your mobile sign-in/users.

## 4) Firebase setup

Initialize Firebase for Flutter once platforms are created:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## 5) Code generation

Generate Freezed and JSON model files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 6) Week 1–2 architecture assets

Architecture and migration parity baseline docs are in `mobile/docs/`:

- `architecture-week1-2.md`
- `data-contracts.md`
- `ux-parity-spec.md`

Global app patterns introduced in `mobile/lib/core/`:

- error handling (`core/error`)
- logging (`core/logging`)
- analytics abstraction (`core/analytics`)
- theming + design tokens (`core/theme`)

## Troubleshooting

### `Cannot add task 'clean' as a task with that name already exists`

If Gradle fails with this error from `mobile/android/build.gradle.kts`, remove any
manually-added `clean` task from that file.

Recent Android Gradle Plugin versions already provide a `clean` task, so adding this
again causes a duplicate-task failure:

```kotlin
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```

Use the built-in task instead:

```bash
./gradlew clean
```
