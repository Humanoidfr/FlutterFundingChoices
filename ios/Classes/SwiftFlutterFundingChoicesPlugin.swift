import Flutter
import UIKit
import UserMessagingPlatform

public class SwiftFlutterFundingChoicesPlugin: NSObject, FlutterPlugin {
    /// The channel method name.
    static let channelName: String = "flutter_funding_choices"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterFundingChoicesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestConsentInformation":
            let arguments: [String: Any?] = call.arguments as! [String: Any?]
            var debugGeography: DebugGeography = toDebugGeography(id: arguments["debugGeography"] as? Int)
            requestConsentInformation(tagForUnderAgeOfConsent: arguments["tagForUnderAgeOfConsent"] as! Bool, testDevicesHashedIds: (arguments["testDevicesHashedIds"] as? [String]) ?? [], debugGeography: debugGeography, result: result)
        case "showConsentForm": showConsentForm(result: result)
        case "reset":
            ConsentInformation.shared.reset()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Requests the consent information.
    private func requestConsentInformation(tagForUnderAgeOfConsent: Bool, testDevicesHashedIds: [String], debugGeography: DebugGeography, result: @escaping FlutterResult) {
        let params = RequestParameters()
        params.isTaggedForUnderAgeOfConsent = tagForUnderAgeOfConsent

        if (testDevicesHashedIds.count > 0) {
            let debugSettings = DebugSettings()
            debugSettings.testDeviceIdentifiers = testDevicesHashedIds
            debugSettings.geography = debugGeography
            params.debugSettings = debugSettings
        }
        
        ConsentInformation.shared.requestConsentInfoUpdate(with: params) { error in
            if error == nil {
                var consentInfo: [String: Any] = [:]
                consentInfo["consentStatus"] = ConsentInformation.shared.consentStatus.rawValue
                consentInfo["isConsentFormAvailable"] = ConsentInformation.shared.formStatus == FormStatus.available
                result(consentInfo)
            } else {
                result(FlutterError(code: "request_error", message: error!.localizedDescription, details: nil))
            }
        }
    }

    /// Shows the consent form.
    private func showConsentForm(result: @escaping FlutterResult) {
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "no_controller", message: "Cannot find key window root view controller.", details: nil))
            return
        }

        ConsentForm.load { consentForm, error in
            guard let consentForm = consentForm else {
                result(FlutterError(code: "show_error", message: error!.localizedDescription, details: nil))
                return
            }

            consentForm.present(from: viewController) { error in
                if error != nil {
                    result(FlutterError(code: "show_error", message: error!.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }

    /// Converts an integer to an UMPDebugGeography instance.
    private func toDebugGeography(id: Int?) -> DebugGeography {
        guard let id = id else {
            return DebugGeography.disabled
        }

        switch id {
        case 0: return DebugGeography.disabled
        case 1: return DebugGeography.EEA
        case 2: return DebugGeography.notEEA
        default: return DebugGeography.disabled
        }
    }
}
