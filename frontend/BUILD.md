# Build Guide — HexBase Retail v3 (Flutter Frontend)

## Prerequisites

- Flutter SDK 3.x (`flutter --version` to verify)
- Dart 3.x (bundled with Flutter)
- Android Studio / Xcode (for mobile targets)
- Chrome (for web target)

---

## 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

---

## 2. Configure API Base URL

Edit `lib/core/network/dio_client.dart` (or a config file) to set the correct backend URL:

```dart
const String kBaseUrl = 'https://your-domain.com/api/v1';
```

Or use `--dart-define` during build:

```bash
flutter build apk --dart-define=BASE_URL=https://your-domain.com/api/v1
```

---

## 3. Build Targets

### Android APK (release)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires macOS + Xcode)

```bash
flutter build ios --release
```

Then archive and distribute via Xcode or `xcrun xcodebuild`.

### Web

```bash
flutter build web --release
```

Output: `build/web/` — deploy as static files behind Nginx.

### Linux Desktop

```bash
flutter build linux --release
```

---

## 4. Run in Debug Mode

```bash
flutter run                     # default device
flutter run -d chrome           # web
flutter run -d linux            # Linux desktop
flutter run --dart-define=BASE_URL=http://localhost:8000/api/v1
```

---

## 5. Run Tests

```bash
flutter test
```

---

## 6. Code Analysis

```bash
flutter analyze
dart fix --apply
```

---

## 7. Signing (Android Release)

Create `android/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=/path/to/your.keystore
```

Ensure `android/app/build.gradle` references `key.properties` for release signing.

---

## 8. Web Deployment

After `flutter build web --release`, deploy `build/web/` to a static host or Nginx:

```nginx
server {
    listen 80;
    server_name app.your-domain.com;
    root /var/www/hexbase-web/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```
