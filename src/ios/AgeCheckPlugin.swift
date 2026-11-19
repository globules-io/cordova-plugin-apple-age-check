import Cordova
import UIKit
import DeclaredAgeRange

@objc(AgeCheckPlugin)
class AgeCheckPlugin: CDVPlugin {

    @objc(checkAge:)
    func checkAge(command: CDVInvokedUrlCommand) {
        guard #available(iOS 26.0, *) else {
            sendError(callbackId: command.callbackId, code: "UNSUPPORTED",
                      message: "Declared Age Range API requires iOS 26 or later")
            return
        }

        guard let gates = ageGates(from: command) else {
            return
        }

        let callbackId = command.callbackId ?? ""
        Task { @MainActor in
            guard let viewController = self.viewController else {
                self.sendError(callbackId: callbackId, code: "NO_VIEW_CONTROLLER",
                               message: "Cordova view controller is null")
                return
            }

            do {
                let response = try await self.requestAgeRange(gates: gates, in: viewController)
                let result = self.result(from: response)
                let pluginResult = CDVPluginResult(status: .ok, messageAs: result)
                self.commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let error as AgeRangeService.Error {
                self.sendError(callbackId: callbackId, code: self.errorCode(error),
                               message: error.localizedDescription)
            } catch {
                self.sendError(callbackId: callbackId, code: "UNKNOWN",
                               message: error.localizedDescription)
            }
        }
    }

    @objc(isSupported:)
    func isSupported(command: CDVInvokedUrlCommand) {
        let supported: Bool
        if #available(iOS 26.0, *) {
            supported = true
        } else {
            supported = false
        }
        let pluginResult = CDVPluginResult(status: .ok, messageAs: supported)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// True when this person is in a region where age assurance applies. Requires iOS 26.2.
    @objc(isEligibleForAgeFeatures:)
    func isEligibleForAgeFeatures(command: CDVInvokedUrlCommand) {
        guard #available(iOS 26.2, *) else {
            sendError(callbackId: command.callbackId, code: "UNSUPPORTED",
                      message: "isEligibleForAgeFeatures requires iOS 26.2 or later")
            return
        }

        let callbackId = command.callbackId ?? ""
        Task { @MainActor in
            do {
                let eligible = try await AgeRangeService.shared.isEligibleForAgeFeatures
                let pluginResult = CDVPluginResult(status: .ok, messageAs: eligible)
                self.commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let error as AgeRangeService.Error {
                self.sendError(callbackId: callbackId, code: self.errorCode(error),
                               message: error.localizedDescription)
            } catch {
                self.sendError(callbackId: callbackId, code: "UNKNOWN",
                               message: error.localizedDescription)
            }
        }
    }

    @available(iOS 26.0, *)
    private func requestAgeRange(gates: [Int], in viewController: UIViewController) async throws -> AgeRangeService.Response {
        switch gates.count {
        case 1:
            return try await AgeRangeService.shared.requestAgeRange(ageGates: gates[0], in: viewController)
        case 2:
            return try await AgeRangeService.shared.requestAgeRange(ageGates: gates[0], gates[1], in: viewController)
        default:
            return try await AgeRangeService.shared.requestAgeRange(
                ageGates: gates[0], gates[1], gates[2], in: viewController)
        }
    }

    @available(iOS 26.0, *)
    private func result(from response: AgeRangeService.Response) -> [String: Any] {
        switch response {
        case .sharing(let ageRange):
            return [
                "sharingStatus": "SHARING",
                "ageLower": ageRange.lowerBound ?? NSNull(),
                "ageUpper": ageRange.upperBound ?? NSNull(),
                "ageRangeDeclaration": declarationName(ageRange.ageRangeDeclaration) ?? NSNull(),
                "activeParentalControls": parentalControlNames(ageRange.activeParentalControls)
            ]
        case .declinedSharing:
            return [
                "sharingStatus": "DECLINED",
                "ageLower": NSNull(),
                "ageUpper": NSNull(),
                "ageRangeDeclaration": NSNull(),
                "activeParentalControls": [String]()
            ]
        }
    }

    /// `confirmed` is only in the iOS 26.5 SDK. The other branch stays exhaustive on earlier SDKs.
    @available(iOS 26.0, *)
    private func declarationName(_ declaration: AgeRangeService.AgeRangeDeclaration?) -> String? {
        guard let declaration = declaration else {
            return nil
        }
        if #available(iOS 26.5, *) {
            switch declaration {
            case .selfDeclared:
                return "SELF_DECLARED"
            case .guardianDeclared:
                return "GUARDIAN_DECLARED"
            case .confirmed:
                return "CONFIRMED"
            case .paymentChecked:
                return "PAYMENT_CHECKED"
            case .governmentIDChecked:
                return "GOVERNMENT_ID_CHECKED"
            case .checkedByOtherMethod:
                return "CHECKED_BY_OTHER_METHOD"
            case .guardianPaymentChecked:
                return "GUARDIAN_PAYMENT_CHECKED"
            case .guardianGovernmentIDChecked:
                return "GUARDIAN_GOVERNMENT_ID_CHECKED"
            case .guardianCheckedByOtherMethod:
                return "GUARDIAN_CHECKED_BY_OTHER_METHOD"
            @unknown default:
                return "UNKNOWN"
            }
        }
        switch declaration {
        case .selfDeclared:
            return "SELF_DECLARED"
        case .guardianDeclared:
            return "GUARDIAN_DECLARED"
        case .paymentChecked:
            return "PAYMENT_CHECKED"
        case .governmentIDChecked:
            return "GOVERNMENT_ID_CHECKED"
        case .checkedByOtherMethod:
            return "CHECKED_BY_OTHER_METHOD"
        case .guardianPaymentChecked:
            return "GUARDIAN_PAYMENT_CHECKED"
        case .guardianGovernmentIDChecked:
            return "GUARDIAN_GOVERNMENT_ID_CHECKED"
        case .guardianCheckedByOtherMethod:
            return "GUARDIAN_CHECKED_BY_OTHER_METHOD"
        @unknown default:
            return "UNKNOWN"
        }
    }

    @available(iOS 26.0, *)
    private func parentalControlNames(_ controls: AgeRangeService.ParentalControls) -> [String] {
        var names: [String] = []
        if controls.contains(.communicationLimits) {
            names.append("COMMUNICATION_LIMITS")
        }
        if controls.contains(.significantAppChangeApprovalRequired) {
            names.append("SIGNIFICANT_APP_CHANGE_APPROVAL_REQUIRED")
        }
        return names
    }

    @available(iOS 26.0, *)
    private func errorCode(_ error: AgeRangeService.Error) -> String {
        switch error {
        case .notAvailable:
            return "NOT_AVAILABLE"
        case .invalidRequest:
            return "INVALID_REQUEST"
        case .declinedOnboarding:
            return "DECLINED_ONBOARDING"
        case .invalidAccount:
            return "INVALID_ACCOUNT"
        case .network:
            return "NETWORK"
        @unknown default:
            return "UNKNOWN"
        }
    }

    /// No argument keeps the previous single gate of 18. An argument is one gate or an array of up to three.
    private func ageGates(from command: CDVInvokedUrlCommand) -> [Int]? {
        let arguments = command.arguments ?? []
        if arguments.isEmpty {
            return [18]
        }

        let values: [Any]
        if let list = arguments[0] as? [Any] {
            values = list
        } else if let list = arguments[0] as? NSArray {
            values = list.compactMap { $0 }
        } else {
            values = arguments
        }

        if values.isEmpty || values.count > 3 {
            sendError(callbackId: command.callbackId, code: "INVALID_AGE_GATES",
                      message: "Pass 1 to 3 age gates. Each band must be at least 2 years wide.")
            return nil
        }

        var gates: [Int] = []
        for value in values {
            guard let gate = integer(from: value), gate >= 1 else {
                sendError(callbackId: command.callbackId, code: "INVALID_AGE_GATES",
                          message: "Each age gate must be a whole number of 1 or more.")
                return nil
            }
            gates.append(gate)
        }

        for index in 1..<gates.count where gates[index] - gates[index - 1] < 2 {
            sendError(callbackId: command.callbackId, code: "INVALID_AGE_GATES",
                      message: "Age gates must increase, and each band must be at least 2 years wide.")
            return nil
        }
        return gates
    }

    private func integer(from value: Any) -> Int? {
        guard let number = value as? NSNumber else {
            return nil
        }
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return nil
        }
        return number.intValue
    }

    private func sendError(callbackId: String?, code: String, message: String) {
        let pluginResult = CDVPluginResult(status: .error, messageAs: [
            "code": code,
            "message": message
        ])
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }
}
