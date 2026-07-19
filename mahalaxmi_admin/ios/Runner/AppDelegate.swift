import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if #available(iOS 14.0, *) {
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FilePickerPlugin")!
      FilePickerPlugin.register(with: registrar)
    }
  }
}

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

    private var pendingResult: FlutterResult?

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "pickImage" {
            pendingResult = result
            let types: [UTType] = [.image]
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            picker.delegate = self
            picker.allowsMultipleSelection = false

            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                result(FlutterError(code: "NO_VC", message: "No root view controller", details: nil))
                pendingResult = nil
                return
            }
            rootVC.present(picker, animated: true, completion: nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            pendingResult?(nil)
            pendingResult = nil
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
