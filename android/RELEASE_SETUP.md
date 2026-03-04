# Android Production Release Setup

This project is configured for a production Android release with:
- Release signing via `android/key.properties`
- R8/ProGuard + resource shrinking for `release`
- `minSdk = 21`
- `targetSdk = flutter.targetSdkVersion` (latest stable from Flutter SDK)
- Multidex enabled

## 1) Create Upload Keystore (one time)

Run from project root:

```powershell
keytool -genkeypair -v `
  -keystore android/upload-keystore.jks `
  -alias upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

## 2) Create `android/key.properties`

Copy `android/key.properties.example` to `android/key.properties` and fill real values:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

`key.properties` and keystore files are ignored in git.

## 3) Build Release APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Split per ABI (recommended for smaller APKs):

```powershell
flutter build apk --release --split-per-abi
```

## 4) Pre-release Verification Checklist

- Login/OTP authentication
- API connectivity on production URLs
- Image capture/upload from camera/gallery
- Invoice PDF/download flow
- Invoice approve/reject/payment flow
- Push notification permission prompt (Android 13+)
- Navigation across all major modules
- Error handling for offline/timeout states

## 5) Play Store Best Practices

- Upload an `.aab` for Play Store distribution:
  - `flutter build appbundle --release`
- Keep `version` in `pubspec.yaml` incremented every release.
- Keep keystore and passwords out of source control.
- Test on at least:
  - Android 8/9 (API 26/28)
  - Android 11/12 (API 30/31)
  - Android 13/14 (API 33/34+)
