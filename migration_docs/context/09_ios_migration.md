# 09 — iOS IPA Preparation

> **Date:** 2026-07-19
> **Status:** Platform scaffolded; ready for cloud build on macOS CI (Codemagic / GitHub Actions).
> **Approach:** Minimum-viable iOS — build success first, platform polish later.

---

## 1. Audit

An iOS readiness audit was performed covering 5 dimensions:

| Dimension | Verdict |
|-----------|---------|
| Dependencies (pubspec.yaml) | ✅ All 16 packages support iOS |
| iOS platform directory | ❌ Did not exist — created via `flutter create --platforms=ios .` |
| Info.plist permissions | ❌ Missing — 3 keys added |
| Native code (MethodChannel) | ❌ Android-only — iOS Swift implementation written |
| Cupertino UI adaptation | ⚠️ None; all-Material UI. Functional but non-native on iOS. Documented in `iOS_Migration_Plan.md` for Phase 2. |
| File I/O / sandbox | ✅ Safe — all writes via `path_provider.getTemporaryDirectory()` |
| `dart:io` usage | ✅ Single file (`share_photo_service.dart`), guarded |

Full audit details: `iOS_Migration_Plan.md` in project root.

---

## 2. Changes Made

### 2.1 iOS Platform Directory

```bash
flutter create --platforms=ios .
```
Generated 40 files: `AppDelegate.swift`, `SceneDelegate.swift`, `Info.plist`, `Assets.xcassets`, Xcode project/workspace, tests, storyboards.

### 2.2 Info.plist — Permission Strings

Added 3 keys to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Mahalaxmi Admin needs access to your photo library to select product images for the catalogue.</string>
<key>NSCameraUsageDescription</key>
<string>Mahalaxmi Admin can use your camera to take product photos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Mahalaxmi Admin saves product images to your photo library when you share them.</string>
```

- `NSPhotoLibraryUsageDescription` — Required. `image_picker` is called from 4 files with `ImageSource.gallery`.
- `NSCameraUsageDescription` — Recommended. `image_picker` pod may auto-inject; providing a string prevents blank permission dialog.
- `NSPhotoLibraryAddUsageDescription` — Recommended. Triggered when user taps "Save Image" from share sheet via `share_plus`.

### 2.3 Custom MethodChannel — iOS Implementation

**Problem:** The admin app replaced `file_picker` with a custom MethodChannel (`com.example.mahalaxmi_admin/file_picker`) for "Browse Files" functionality, implemented only in `MainActivity.kt` (Android). No iOS handler existed — calling it on iOS would throw `MissingPluginException`.

**Fix:** Created `ios/Runner/FilePickerPlugin.swift` (58 lines):
- Registers method channel with name `com.example.mahalaxmi_admin/file_picker`
- Handles `pickImage` method using `UIDocumentPickerViewController` for `[.image]`
- Uses `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource` for sandbox access
- Reads file as `Data`, returns as `FlutterStandardTypedData(bytes:)` for Dart `Uint8List`
- Handles cancellation and errors gracefully

**Registration:** Updated `AppDelegate.swift` to call `FilePickerPlugin.register(with:)` inside `didInitializeImplicitFlutterEngine`, guarded with `@available(iOS 14.0, *)`.

### 2.4 App Icons

- **pubspec.yaml:** Changed `flutter_launcher_icons` → `ios: true` (was `false`)
- **Generated:** Ran `flutter pub run flutter_launcher_icons` which overwrote default iOS icon set in `Assets.xcassets/AppIcon.appiconset/` with `mbadmin.png`-based icons
- **Warning noted:** Icon has alpha channel; Apple App Store rejects icons with alpha. If submitting to TestFlight/App Store, add `remove_alpha_ios: true` to `flutter_launcher_icons` config.

### 2.5 iOS Target

- `Podfile` will be generated automatically on macOS during `flutter build ios`
- `iOS_Migration_Plan.md` specifies `platform :ios, '13.0'` as the minimum target (required by `supabase_flutter` dependencies)

---

## 3. Build Command

```bash
cd mahalaxmi_admin
flutter build ios --release --no-codesign \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```

This produces `build/ios/iphoneos/Runner.app`. To generate an unsigned `.ipa`:

```bash
cd build/ios/iphoneos
mkdir -p Payload && cp -r Runner.app Payload/
zip -r admin_unsigned.ipa Payload/
```

---

## 4. CI/CD Configuration

Two pipeline definitions exist in `iOS_Migration_Plan.md`:

| Platform | File | Runner |
|----------|------|--------|
| Codemagic | Inline in `iOS_Migration_Plan.md §4.1` | `mac_mini_m2` |
| GitHub Actions | Inline in `iOS_Migration_Plan.md §4.2` | `macos-latest` |

Both pipelines:
1. Run `flutter create --platforms=ios .` (scaffold iOS dir)
2. Run `flutter pub run flutter_launcher_icons` (icons)
3. Run `pod install --repo-update` (CocoaPods)
4. Run `flutter build ios --release --no-codesign` (build)
5. Upload `Runner.app` as artifact

---

## 5. Remaining Work

### Phase 2 — Platform Polish (before TestFlight)
- Platform-adaptive GoRouter transitions (`pageBuilder:` with `CupertinoPageRoute` for iOS)
- Platform-adaptive bottom nav (`CupertinoTabBar` on iOS vs `NavigationBar` on Android)
- Platform-adaptive exit dialog (`CupertinoAlertDialog` on iOS)
- Temp file cleanup in `share_photo_service.dart`

### Phase 3 — Full Native UX (before App Store)
- Systematic Cupertino adaptation: `CupertinoNavigationBar`, `CupertinoTextField`, `CupertinoSwitch`, `CupertinoSlider`
- Platform-adaptive theming (`CupertinoThemeData` on iOS)
- Test on physical iPhone

### Non-Issues (no action needed)
- Push notifications: not used
- Location: not used
- Background execution: not used
- Keychain: not used (SharedPreferences acceptable for private enterprise app)
- WebSocket (Supabase realtime): allowed by default on iOS
- ATS exceptions: not needed (all HTTPS)

---

## 6. Files Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `ios/Runner/Info.plist` | Modified | Added 3 permission strings |
| `ios/Runner/FilePickerPlugin.swift` | Created | Swift MethodChannel for file picking |
| `ios/Runner/AppDelegate.swift` | Modified | Registers FilePickerPlugin |
| `pubspec.yaml` | Modified | `ios: false` → `true` for launcher icons |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | Modified | Generated iOS icon set |
| `ios/` (directory) | Created | 40 files via `flutter create --platforms=ios .` |
| `iOS_Migration_Plan.md` | Created | Comprehensive audit + build plan |
