import Foundation
import React
import StoreKit

#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif
import UIKit

// Check if DeclaredAgeRange type exists (iOS 18+) or handled via availability checks
// Removing generic canImport because it's part of StoreKit usually

@objc(StoreAgeSignalsNativeModulesSwift)
public class StoreAgeSignalsNativeModulesSwift: NSObject {

  @objc(multiply:withB:withResolver:withRejecter:)
  public func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve(a*b)
  }
    
  @objc
  public func requestIOSDeclaredAgeRange(
    firstThresholdAge: NSNumber,
    secondThresholdAge: NSNumber,
    thirdThresholdAge: NSNumber,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
      // NOTE: Using patterns from reference implementation
      #if compiler(>=6.0) && canImport(DeclaredAgeRange)
      // The SDK strictly requires iOS 26.0+ for AgeRangeService
      if #available(iOS 26.0, *) {
          Task { @MainActor in
              do {
                  guard let viewController = self.topViewController() else {
                       reject("VIEW_CONTROLLER_ERROR", "Could not find top view controller", nil)
                       return
                  }
                  
                  let t1 = Int(truncating: firstThresholdAge)
                  let t2 = Int(truncating: secondThresholdAge)
                  let t3 = Int(truncating: thirdThresholdAge)
                  
                  // Use AgeRangeService as per reference
                  let response = try await AgeRangeService.shared.requestAgeRange(
                      ageGates: t1, t2, t3,
                      in: viewController
                  )
                  
                  var statusString = "declined"
                  var lowerBound: NSNumber? = nil
                  var upperBound: NSNumber? = nil
                  var ageRangeDeclaration: String? = nil
                  var parentalControls: [String: Bool] = [:]

                  switch response {
                  case .sharing(let declaration):
                       statusString = "sharing"

                       // Extract age range declaration type
                       if let declType = declaration.ageRangeDeclaration {
                           switch declType {
                           case .selfDeclared:
                               ageRangeDeclaration = "selfDeclared"
                           case .guardianDeclared:
                               ageRangeDeclaration = "guardianDeclared"
                           case .checkedByOtherMethod:
                               ageRangeDeclaration = "checkedByOtherMethod"
                           case .guardianCheckedByOtherMethod:
                               ageRangeDeclaration = "guardianCheckedByOtherMethod"
                           case .governmentIDChecked:
                               ageRangeDeclaration = "governmentIDChecked"
                           case .guardianGovernmentIDChecked:
                               ageRangeDeclaration = "guardianGovernmentIDChecked"
                           case .paymentChecked:
                               ageRangeDeclaration = "paymentChecked"
                           case .guardianPaymentChecked:
                               ageRangeDeclaration = "guardianPaymentChecked"
                           @unknown default:
                               ageRangeDeclaration = "unknown"
                           }
                       }

                       if let lower = declaration.lowerBound {
                           lowerBound = NSNumber(value: lower)
                       }
                       if let upper = declaration.upperBound {
                           upperBound = NSNumber(value: upper)
                       }

                       // Parse parental controls as structured object
                       let controls = declaration.activeParentalControls
                       parentalControls["communicationLimits"] = controls.contains(.communicationLimits)
                       parentalControls["significantAppChangeApprovalRequired"] = controls.contains(.significantAppChangeApprovalRequired)

                  case .declinedSharing:
                       statusString = "declined"
                  @unknown default:
                       statusString = "unknown"
                  }

                  let resultMap: [String: Any?] = [
                      "status": statusString,
                      "lowerBound": lowerBound,
                      "upperBound": upperBound,
                      "ageRangeDeclaration": ageRangeDeclaration,
                      "parentalControls": parentalControls.isEmpty ? nil : parentalControls
                  ]
                  resolve(resultMap)
                  
              } catch let error as AgeRangeService.Error {
                  var errorMsg = error.localizedDescription
                  switch error {
                  case .notAvailable:
                      errorMsg += ". (Hint: Missing Entitlement OR Feature is unavailable on Simulator. Verify on real device.)"
                  case .invalidRequest:
                      errorMsg += ". (Hint: Invalid request, check requested ages.)"
                  @unknown default:
                      break
                  }
                  reject("ERR_IOS_AGE_REQUEST", errorMsg, error)
              } catch {
                  reject("ERR_IOS_AGE_REQUEST", error.localizedDescription, error)
              }
          }
      } else {
          resolve(["status": nil, "error": "Requires iOS 26.0+"])
      }
      #else
      resolve(["status": nil, "error": "SDK not available"])
      #endif
  }
  
  // Helper to get top view controller
  private func topViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
          let rootViewController = window.rootViewController else {
      return nil
    }

    var topController = rootViewController
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }

    return topController
  }
}
