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

## 3) Firebase setup

Initialize Firebase for Flutter once platforms are created:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## 4) Code generation

Generate Freezed and JSON model files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
