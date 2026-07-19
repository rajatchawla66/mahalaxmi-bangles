# iOS Migration Plan — Mahalaxmi Admin App

> **Generated:** 2026-07-19
> **Target:** Unsigned `.ipa` for cloud compilation (Codemagic / GitHub Actions)
> **Strategy:** Minimum-viable iOS compatibility — optimize for build success, not pixel-perfect native UX.

---

## 1. Audit Summary

### Current Status: iOS NOT supported

| Area | Status | Details |
|------|--------|---------|
| iOS platform directory | ❌ Missing | `mahalaxmi_admin/ios/` does not exist |
| `flutter_launcher_icons` | ❌ Disabled | `ios: false` in pubspec.yaml |
| Custom native code | ❌ Android-only | MethodChannel in `MainActivity.kt` has no iOS equivalent |
| Info.plist permissions | ❌ Not configured | No iOS assets exist yet |
| Cupertino adaptation | ❌ None | 100% Material widgets, zero platform-adaptive code |
| GoRouter transitions | ⚠️ Default | Uses `builder:` (MaterialPageRoute) - no `pageBuilder:` for CupertinoPageRoute |
| File I/O / sandbox | ✅ Safe | All writes use `getTemporaryDirectory()` via `path_provider` |
| `dart:io` usage | ✅ Isolated | Single file (`share_photo_service.dart`) — guarded usage |
| Platform detection | ❌ Missing | No `defaultTargetPlatform` or `Theme.of(context).platform` checks |
| Network security | ✅ OK | All HTTPS (Supabase), no ATS exceptions needed |
| Push notifications | ✅ Not used | No `firebase_messaging` or `flutter_local_notifications` |

### Critical Path

```
Without these, the build will fail:
1. flutter create --platforms=ios .          ← generates ios/
2. Write Swift MethodChannel for file picker  ← replaces missing Android-only code
3. Add Info.plist permission strings          ← required by image_picker pod
4. Add iOS app icons                          ← flutter_launcher_icons or manual
5. cd ios && pod install                      ← resolves CocoaPods
6. flutter build ios --release --no-codesign  ← produces unsigned .ipa
```

---

## 2. iOS Configuration Tasks

### 2.1 Scaffold iOS Platform Directory

```bash
cd mahalaxmi_admin
flutter create --platforms=ios .
```

This generates:
- `ios/Runner.xcworkspace`
- `ios/Podfile`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Assets.xcassets/`

### 2.2 Info.plist — Permission Strings

Add the following entries to `ios/Runner/Info.plist` inside the `<dict>` block:

```xml
<!-- Required: image_picker gallery access (4 call sites in admin app) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Mahalaxmi Admin needs access to your photo library to select product images for the catalogue.</string>

<!-- Recommended: image_picker may auto-inject this; provide a string to avoid blank permission dialog -->
<key>NSCameraUsageDescription</key>
<string>Mahalaxmi Admin can use your camera to take product photos.</string>

<!-- Recommended: share_plus — triggered when user taps "Save Image" from share sheet -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Mahalaxmi Admin saves product images to your photo library when you share them.</string>
```

**Rationale:** All `ImagePicker` calls in the codebase use `ImageSource.gallery` only (4 files: `add_item_page.dart`, `item_edit_page.dart`, `bulk_trading_cost_page.dart`, `manage_categories_page.dart`). The camera key is included defensively — the `image_picker` pod may inject it automatically, and an empty permission string causes a crash.

### 2.3 Podfile — Minimum iOS Target

In `ios/Podfile`, ensure the platform target is at least **13.0** (required by supabase_flutter dependencies):

```ruby
platform :ios, '13.0'
```

After scaffolding, also run:

```bash
cd ios && pod install --repo-update
```

If CocoaPods is not installed on the build machine, add this to the CI pipeline:

```bash
gem install cocoapods
pod install --repo-update
```

### 2.4 App Icons

Option A — Enable `flutter_launcher_icons`:

```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true          # change from false to true
  image_path: "assets/mbadmin.png"
  min_sdk_android: 23
```

Then generate:

```bash
flutter pub run flutter_launcher_icons
```

Option B — Manual placement (for CI without flutter_launcher_icons):
Place `mbadmin.png` into `ios/Runner/Assets.xcassets/AppIcon.appiconset/` at required sizes. The recommended sizes for iOS are:

```
40x40, 60x60, 58x58, 87x87, 80x80, 120x120, 180x180, 1024x1024
```

### 2.5 Native MethodChannel — iOS Implementation

The admin app replaces `file_picker` with a custom MethodChannel. An iOS Swift implementation must be written.

**Create** `ios/Runner/FilePickerPlugin.swift`:

```swift
import UIKit
import Flutter
import UniformTypeIdentifiers

@available(iOS 14.0, *)
class FilePickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.mahalaxmi_admin/file_picker",
            binaryMessenger: registrar.messenger()
        )
        let instance = FilePickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "pickImage" {
            pickImage(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private var pendingResult: FlutterResult?

    private func pickImage(result: @escaping FlutterResult) {
        pendingResult = result
        let types: [UTType] = [.image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false

        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "NO_VC", message: "No root view controller", details: nil))
            return
        }
        rootVC.present(picker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            pendingResult?(nil)
            return
        }
        url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            pendingResult?(FlutterStandardTypedData(bytes: data))
        } catch {
            pendingResult?(FlutterError(code: "READ_ERR", message: error.localizedDescription, details: nil))
        }
        pendingResult = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pendingResult?(nil)
        pendingResult = nil
    }
}
```

**Register in** `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        FilePickerPlugin.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 2.6 Build Runner (if using generated code)

If the admin app uses `riverpod_generator` or other code generation, ensure the CI runs:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. Code Modification Tasks

### 3.1 Critical: Platform-Safe File I/O

**File:** `mahalaxmi_admin/lib/services/share_photo_service.dart`

**Problem:** Uses `dart:io File()` without `kIsWeb` guard. Comment claims web-compatibility but code would crash on web.

**Fix — guard the entire shareBytes method:**

```dart
static Future<void> shareBytes({
  required List<Uint8List> bytesList,
  required List<String> fileNames,
}) async {
  if (kIsWeb) {
    // Web: use Share.shareXFiles with XFile.fromData
    final xFiles = bytesList.asMap().entries.map((e) =>
      XFile.fromData(e.value, mimeType: 'image/jpeg', name: fileNames[e.key])
    ).toList();
    await Share.shareXFiles(xFiles);
    return;
  }
  final dir = await getTemporaryDirectory();
  final xFiles = <XFile>[];
  for (int i = 0; i < bytesList.length; i++) {
    final file = File('${dir.path}/${fileNames[i]}');
    await file.writeAsBytes(bytesList[i]);
    xFiles.add(XFile(file.path, mimeType: 'image/jpeg'));
  }
  await Share.shareXFiles(xFiles);

  // Cleanup temp files
  for (final xf in xFiles) {
    try { await File(xf.path).delete(); } catch (_) {}
  }
}
```

### 3.2 Recommended: Platform-Adaptive GoRouter Transitions

**File:** `mahalaxmi_admin/lib/app/router.dart`

**Problem:** All routes use `builder:` which creates a `MaterialPageRoute`. On iOS, the slide-from-bottom animation looks non-native.

**Fix — add an adaptive `pageBuilder` helper:**

In `router.dart`, import `dart:io` (guarded):

```dart
import 'dart:io' show Platform;
```

Then create a helper function:

```dart
/// Returns CupertinoPageRoute on iOS, MaterialPageRoute on Android.
Page<T> _adaptivePage<T>(BuildContext context, GoRouterState state, Widget child) {
  if (Platform.isIOS) {
    return CupertinoPageRoute(
      builder: (_) => child,
      settings: state,
    );
  }
  return MaterialPageRoute(
    builder: (_) => child,
    settings: state,
  );
}
```

Use on full-screen routes (routes with `parentNavigatorKey`):

```dart
GoRoute(
  path: '/orders/:orderId',
  name: 'orderDetail',
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (context, state) => _adaptivePage(context, state, OrderDetailPage(
    orderId: int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0,
  )),
),
```

> **Alternative (minimum effort):** GoRouter defaults to `CupertinoPageRoute` when it detects iOS. However, the admin app's `builder:` route factory explicitly creates `MaterialPageRoute`. Changing to `pageBuilder:` without specifying the route type also defaults to platform-appropriate transitions on newer Flutter versions. Test on device to verify.

### 3.3 Recommended: Platform-Adaptive Navigation Bar

**File:** `mahalaxmi_admin/lib/app/router.dart` (lines 368–402)

**Fix — switch between NavigationBar and CupertinoTabBar:**

```dart
import 'dart:io' show Platform;

// In _AdminShellState.build:
final isIOS = Platform.isIOS;

// Replace NavigationBar with:
if (isIOS) {
  return CupertinoTabBar(
    currentIndex: currentIndex,
    onTap: (index) { ... },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      ...
    ],
  );
} else {
  return NavigationBar(...);
}
```

### 3.4 Recommended: Platform-Adaptive Dialogs

**File:** `mahalaxmi_admin/lib/app/router.dart` (lines 343–358)

**Fix — use platform-appropriate exit dialog:**

Add an import and helper:

```dart
import 'dart:io' show Platform;

Future<bool?> _showExitDialog(BuildContext context) {
  if (Platform.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exit App'),
      content: const Text('Are you sure you want to exit?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit')),
      ],
    ),
  );
}
```

> **Scope note:** This affects ~34+ `AlertDialog` instances across the app. A full sweep is post-MVP. Focus on the shell exit dialog (router.dart) for the initial build; other dialogs can be addressed incrementally.

### 3.5 Minimum: Widget-Specific Cupertino Adaptations

For the MVP build, only the **shell exit dialog** (3.4) is critical. The remaining Material widgets (AppBar, TextField, Switch, Slider) render correctly on iOS — they look Material-styled but are fully functional.

---

## 4. CI/CD Pipeline (Codemagic / GitHub Actions)

### 4.1 Codemagic (`codemagic.yaml`)

```yaml
workflows:
  admin-ios:
    name: Admin iOS Unsigned IPA
    instance_type: mac_mini_m2
    max_build_duration: 60
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      vars:
        SUPABASE_URL: Encrypted(...)
        SUPABASE_ANON_KEY: Encrypted(...)
    scripts:
      - name: Set up iOS
        script: |
          cd mahalaxmi_admin
          flutter create --platforms=ios . --project-name mahalaxmi_admin
      - name: Generate launcher icons
        script: |
          cd mahalaxmi_admin
          flutter pub get
          flutter pub run flutter_launcher_icons
      - name: Install pods
        script: |
          cd mahalaxmi_admin/ios
          pod install --repo-update
      - name: Build unsigned IPA
        script: |
          cd mahalaxmi_admin
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=$SUPABASE_URL \
            --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
    artifacts:
      - mahalaxmi_admin/build/ios/iphoneos/*.app
      - mahalaxmi_admin/build/ios/iphoneos/Runner.app
    publishing:
      email:
        recipients:
          - rajatchawla66@gmail.com
```

### 4.2 GitHub Actions (`.github/workflows/ios_build.yml`)

```yaml
name: Build iOS Admin (Unsigned IPA)

on:
  workflow_dispatch:

jobs:
  build-ios:
    runs-on: macos-latest
    defaults:
      run:
        working-directory: mahalaxmi_admin

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          channel: 'stable'

      - name: Create iOS platform
        run: flutter create --platforms=ios . --project-name mahalaxmi_admin

      - name: Install dependencies
        run: flutter pub get

      - name: Generate app icons
        run: flutter pub run flutter_launcher_icons

      - name: Install CocoaPods
        run: |
          gem install cocoapods
          cd ios && pod install --repo-update

      - name: Build unsigned IPA
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: Runner.app
          path: mahalaxmi_admin/build/ios/iphoneos/Runner.app
```

### 4.3 Build Output Paths

| Artifact | Path |
|----------|------|
| Uncompiled app bundle | `mahalaxmi_admin/build/ios/iphoneos/Runner.app` |
| Unsigned .app (debug) | `mahalaxmi_admin/build/ios/iphoneos/Runner.app` |
| Symbols (dSYM) | `mahalaxmi_admin/build/ios/iphoneos/Runner.app.dSYM` |

> **Note:** `flutter build ios --no-codesign` produces a `.app` bundle, not a `.ipa`. To generate a `.ipa` without signing, use:
> ```bash
> cd build/ios/iphoneos
> mkdir -p Payload && cp -r Runner.app Payload/
> zip -r admin_unsigned.ipa Payload/
> ```

---

## 5. Dependency Compatibility Matrix

| Package | Admin Version | iOS Support | iOS Min Target | Notes |
|---------|--------------|-------------|----------------|-------|
| `flutter_riverpod` | ^2.6.0 | ✅ Full | — | Pure Dart |
| `riverpod` | ^2.6.0 | ✅ Full | — | Pure Dart |
| `go_router` | ^14.6.0 | ✅ Full | — | Pure Dart |
| `supabase_flutter` | ^2.8.0 | ✅ Full | 13.0 | WebSocket for realtime |
| `image_picker` | ^1.1.0 | ✅ Full | — | Requires NSPhotoLibraryUsageDescription |
| `crop_your_image` | ^1.0.3 | ✅ Full | — | Pure Dart widget |
| `share_plus` | ^10.1.0 | ✅ Full | — | Uses UIActivityViewController |
| `path_provider` | ^2.1.0 | ✅ Full | — | iOS sandbox-safe |
| `printing` | ^5.11.0 | ✅ Full | — | Uses UIPrintInteractionController |
| `image` | ^4.8.0 | ✅ Full | — | Pure Dart |
| `http` | ^1.2.0 | ✅ Full | — | Standard network |
| `shared_preferences` | ^2.2.0 | ✅ Full | — | NSUserDefaults backend |
| `intl` | ^0.20.0 | ✅ Full | — | Pure Dart |
| `uuid` | ^4.5.0 | ✅ Full | — | Pure Dart |
| `freezed_annotation` | ^2.4.0 | ✅ Full | — | Code gen only |
| `json_annotation` | ^4.9.0 | ✅ Full | — | Code gen only |
| `pdf` (shared) | ^3.10.8 | ✅ Full | — | Pure Dart |

**No packages with iOS incompatibility found.** All dependencies support iOS.

---

## 6. Blockers and Risks

### Blockers (must fix before build)

| # | Blocker | Impact | Fix |
|---|---------|--------|-----|
| B1 | `ios/` directory missing | `flutter build ios` fails immediately | `flutter create --platforms=ios .` |
| B2 | MethodChannel has no iOS handler | "Browse Files" tap crashes with MissingPluginException on iOS | Write `FilePickerPlugin.swift` + register in AppDelegate |
| B3 | No Info.plist permission strings | `image_picker` shows blank dialog or crashes | Add NSPhotoLibraryUsageDescription + NSCameraUsageDescription |
| B4 | No iOS app icons | Build warning; generic white icon on device | Enable `flutter_launcher_icons` with `ios: true` |

### Risks (should address before release)

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | All-Material UI looks non-native on iOS | Medium | Add Platform.isIOS checks for key widgets (navigation bar, dialogs, transitions) |
| R2 | Temp file cleanup missing in share service | Low | Add cleanup loop after Share.shareXFiles completes |
| R3 | Cart persistence via SharedPreferences (NSUserDefaults) may hit size limits | Low | Monitor cart JSON size; migrate to file-based storage if >100KB |
| R4 | No date pickers currently — but if added for trading ledger, must use CupertinoDatePicker | Low | Use adaptive date picker pattern when adding ledger feature |
| R5 | Platform detection code uses `dart:io Platform` which is compile-time available on iOS | Low | Import guarded by `dart:io` — safe on iOS, crashes on web |

### Non-Issues

| Topic | Status |
|-------|--------|
| Push notifications | Not used — no setup needed |
| Location services | Not used — no setup needed |
| Background execution | Not used — no capabilities needed |
| Keychain / secure storage | Not used (SharedPreferences is acceptable for private enterprise app) |
| WebSocket / Supabase realtime | Allowed by default on iOS — no entitlement needed |
| HTTP (non-HTTPS) connections | None — all Supabase URLs use HTTPS |
| Deep linking / universal links | Not implemented — no entitlement needed |

---

## 7. Implementation Order (Build-First)

### Phase 1 — Build Success (Day 1)
1. `flutter create --platforms=ios .` scaffolds iOS directory
2. Add Info.plist permission keys (NSPhotoLibraryUsageDescription, NSCameraUsageDescription, NSPhotoLibraryAddUsageDescription)
3. Write `FilePickerPlugin.swift` + register in `AppDelegate.swift`
4. Enable `flutter_launcher_icons` with `ios: true`
5. Set `platform :ios, '13.0'` in Podfile
6. Run `pod install --repo-update`
7. Run `flutter build ios --release --no-codesign`

### Phase 2 — Platform Polish (Day 2-3)
8. Platform-adaptive GoRouter page transitions (optional - test default first)
9. Platform-adaptive exit dialog (router.dart Exit App)
10. Platform-adaptive bottom nav (NavigationBar vs CupertinoTabBar)
11. Temp file cleanup in `share_photo_service.dart`

### Phase 3 — Full Native UX (Week 2+)
12. Systematic Cupertino adaptation across all pages (AppBar → CupertinoNavigationBar, AlertDialog → CupertinoAlertDialog, TextField → CupertinoTextField)
13. Platform-adaptive theming in `theme.dart` (Material 3 on Android, CupertinoThemeData on iOS)
14. Test on physical iPhone via TestFlight / ad-hoc

---

## 8. Verification Checklist

- [ ] `flutter create --platforms=ios .` completes without errors
- [ ] `flutter pub get` resolves all dependencies for iOS
- [ ] `cd ios && pod install` completes without errors
- [ ] `flutter build ios --release --no-codesign` produces `build/ios/iphoneos/Runner.app`
- [ ] App launches on iOS simulator (basic smoke test)
- [ ] Login page renders and accepts credentials
- [ ] Dashboard loads data from Supabase
- [ ] Order list and detail pages display correctly
- [ ] Catalogue pages load and show categories/items
- [ ] Image picker opens gallery from at least one page
- [ ] "Browse Files" opens UIDocumentPickerViewController (does not crash)
- [ ] Share photos flow completes without crash
- [ ] All navigation transitions work (back button, tab switching, deep links)
- [ ] Exit dialog shows platform-appropriate style (CupertinoAlertDialog on iOS)
- [ ] No MissingPluginException in console at startup or during image picking
