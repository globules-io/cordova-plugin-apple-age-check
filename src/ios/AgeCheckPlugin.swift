import Cordova
import DeclaredAgeRange

@objc(AgeCheckPlugin)
class AgeCheckPlugin: CDVPlugin {

    @objc(checkAge:)
    func checkAge(command: CDVInvokedUrlCommand) {
        // Guard for iOS 26+
        guard #available(iOS 26.0, *) else {
            let pluginResult = CDVPluginResult(status: .error,
                                               messageAs: "Declared Age Range API requires iOS 26 or later")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                // Request with age gate (you can pass array like [13, 16, 18] for finer control)
                let response = try await AgeRangeService.shared.requestAgeRange(ageGates: 18)

                var result: [String: Any] = [:]

                switch response {
                case .sharing(let ageRange):
                    result["userStatus"] = "DECLARED"                    // Normalized to match Android
                    result["ageLower"] = ageRange.lowerBound ?? NSNull()
                    result["ageUpper"] = ageRange.upperBound ?? NSNull()
                    result["mostRecentApprovalDate"] = NSNull()          // Not available on iOS
                    result["installId"] = NSNull()                       // Not available on iOS

                case .declinedSharing:
                    result["userStatus"] = "DECLINED"
                    result["ageLower"] = NSNull()
                    result["ageUpper"] = NSNull()
                }

                let pluginResult = CDVPluginResult(status: .ok, messageAs: result)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)

            } catch let error as AgeRangeService.Error {
                let errorMsg = "AgeRangeService error: \(error)"
                let pluginResult = CDVPluginResult(status: .error, messageAs: errorMsg)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            } catch {
                let pluginResult = CDVPluginResult(status: .error,
                                                   messageAs: "Unknown error: \(error.localizedDescription)")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    @objc(isSupported:)
    func isSupported(command: CDVInvokedUrlCommand) {
        let supported = #available(iOS 26.0, *) && AgeRangeService.isSupported
        let pluginResult = CDVPluginResult(status: .ok, messageAs: supported ? 1 : 0)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
}