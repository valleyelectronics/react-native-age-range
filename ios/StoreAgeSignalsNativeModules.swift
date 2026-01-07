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
                  var parentControls: String? = nil
                  
                  switch response {
                  case .sharing(let declaration):
                       if let declStatus = declaration.ageRangeDeclaration {
                           statusString = String(describing: declStatus)
                       } else {
                           statusString = "sharing"
                       }
                       
                       if let lower = declaration.lowerBound {
                           lowerBound = NSNumber(value: lower)
                       }
                       if let upper = declaration.upperBound {
                           upperBound = NSNumber(value: upper)
                       }
                       
                       let controlsRaw = declaration.activeParentalControls.rawValue
                       parentControls = "\(controlsRaw)"
                       
                  case .declinedSharing:
                       statusString = "declined"
                  @unknown default:
                       statusString = "unknown"
                  }
                  
                  let resultMap: [String: Any?] = [
                      "status": statusString,
                      "parentControls": parentControls,
                      "lowerBound": lowerBound,
                      "upperBound": upperBound,
                      "error": nil
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
  
  @objc
  public func isEligibleForAgeFeatures(
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
      #if compiler(>=6.0) && canImport(DeclaredAgeRange)
      // isEligibleForAgeFeatures requires iOS 26.2+
      if #available(iOS 26.2, *) {
          Task {
            do {
              let isEligible = try await AgeRangeService.shared.isEligibleForAgeFeatures
              let resultMap: [String: Any?] = [
                "isEligible": isEligible,
                "error": nil
              ]
              resolve(resultMap)
            } catch {
              reject("ERR_IOS_AGE_ELIGIBLE", error.localizedDescription, error)
            }
          }
      } else {
          resolve(["isEligible": false, "error": "Requires iOS 26.2+"])
      }
      #else
      resolve(["isEligible": false, "error": "SDK not available"])
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
