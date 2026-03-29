<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# Run and deploy your AI Studio app

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/87ceaf75-f592-4224-be82-5e9fe92985ab

## Run Locally

**Prerequisites:** Node.js

1. Install dependencies:
   `npm install`
2. Set the `GEMINI_API_KEY` in `.env.local` to your Gemini API key.
3. Run the app:
   `npm run dev`

## Build a debug APK (Android)

This repo now includes a native Android WebView shell under `android/` that loads the built Vite app from bundled assets.

### Prerequisites

- Android SDK installed (set `ANDROID_SDK_ROOT` or create `android/local.properties` with `sdk.dir=/path/to/Android/Sdk`)
- Java 17+
- Gradle 8+

### Build steps

1. Build and sync the web app into Android assets:
   `npm run android:sync`
2. Build the debug APK:
   `npm run android:debug`

### Output APK

After a successful build, the debug APK is at:

`android/app/build/outputs/apk/debug/app-debug.apk`

Install on a connected device:

`adb install -r android/app/build/outputs/apk/debug/app-debug.apk`

To inspect WebView with Chrome DevTools (debug builds):

1. Enable Developer Options + USB debugging on device.
2. Connect device and open `chrome://inspect` in desktop Chrome.
3. Select the app WebView target.
