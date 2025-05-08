import Flutter
import UIKit
import LocalAuthentication

public class AztecDartPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example.aztec_dart", binaryMessenger: registrar.messenger())
    let instance = AztecDartPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getApplicationDirectory":
      let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
      result(directory)
      
    case "extractLibrary":
      guard let args = call.arguments as? [String: Any],
            let libraryName = args["libraryName"] as? String,
            let directory = args["directory"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Library name and directory must be provided", details: nil))
        return
      }
      
      do {
        let success = try NativeLibraryLoader.extractNativeLibrary(libraryName: libraryName, directory: directory)
        if success {
          result(nil)
        } else {
          result(FlutterError(code: "EXTRACTION_FAILED", message: "Failed to extract library", details: nil))
        }
      } catch {
        result(FlutterError(code: "EXTRACTION_ERROR", message: error.localizedDescription, details: nil))
      }
      
    case "isBiometricAvailable":
      let context = LAContext()
      var error: NSError?
      let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
      result(canEvaluate)
      
    case "authenticateWithBiometrics":
      guard let args = call.arguments as? [String: Any],
            let reason = args["reason"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Reason must be provided", details: nil))
        return
      }
      
      authenticateWithBiometrics(reason: reason, completion: result)
      
    case "getDeviceId":
      result(SecurityUtils.getDeviceId())
      
    case "isDeviceRooted":
      result(SecurityUtils.isDeviceJailbroken())
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func authenticateWithBiometrics(reason: String, completion: @escaping FlutterResult) {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
        DispatchQueue.main.async {
          if let error = error {
            completion(FlutterError(code: "AUTHENTICATION_ERROR", message: error.localizedDescription, details: nil))
          } else {
            completion(success)
          }
        }
      }
    } else {
      if let error = error {
        completion(FlutterError(code: "BIOMETRIC_UNAVAILABLE", message: error.localizedDescription, details: nil))
      } else {
        completion(FlutterError(code: "BIOMETRIC_UNAVAILABLE", message: "Biometric authentication is not available", details: nil))
      }
    }
  }
}
