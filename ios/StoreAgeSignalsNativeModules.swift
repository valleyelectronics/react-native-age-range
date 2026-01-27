import Foundation
import React
import StoreKit

#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

#if canImport(PermissionKit)
import PermissionKit
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
                      "parentalControls": parentalControls.isEmpty ? nil : parentalControls,
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

  // MARK: - PermissionKit: Significant Change API

  @objc
  public func requestSignificantChangeApproval(
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
      #if compiler(>=6.0) && canImport(PermissionKit)
      if #available(iOS 26.0, *) {
          Task { @MainActor in
              do {
                  guard let viewController = self.topViewController() else {
                      reject("VIEW_CONTROLLER_ERROR", "Could not find top view controller", nil)
                      return
                  }

                  var topic = SignificantAppUpdateTopic()
                  var question = PermissionQuestion(significantAppUpdateTopic: topic)

                  try await AskCenter.current.ask(question: question, in: viewController)

                  // If we get here without error, the request was shown successfully
                  // The actual approval status is delivered asynchronously via updates
                  let resultMap: [String: Any?] = [
                      "status": "pending",
                      "error": nil
                  ]
                  resolve(resultMap)

              } catch {
                  var errorMsg = error.localizedDescription
                  if errorMsg.contains("region") {
                      errorMsg += ". (Hint: User may be in a region that does not support this feature.)"
                  }
                  reject("ERR_IOS_SIGNIFICANT_CHANGE", errorMsg, error)
              }
          }
      } else {
          resolve(["status": nil, "error": "Requires iOS 26.0+"])
      }
      #else
      resolve(["status": nil, "error": "PermissionKit SDK not available"])
      #endif
  }

  // MARK: - PermissionKit: Communication Limits API

  @objc
  public func requestCommunicationPermission(
    contacts: NSArray,
    actions: NSArray,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
      #if compiler(>=6.0) && canImport(PermissionKit)
      if #available(iOS 26.2, *) {
          Task { @MainActor in
              do {
                  guard let viewController = self.topViewController() else {
                      reject("VIEW_CONTROLLER_ERROR", "Could not find top view controller", nil)
                      return
                  }

                  // Parse contacts from JS
                  var personInfoList: [PersonInformation] = []
                  for contact in contacts {
                      guard let contactDict = contact as? [String: Any],
                            let handleValue = contactDict["handle"] as? String,
                            let handleKindStr = contactDict["handleKind"] as? String else {
                          continue
                      }

                      let handleKind: CommunicationHandle.Kind
                      switch handleKindStr {
                      case "phoneNumber":
                          handleKind = .phoneNumber
                      case "email":
                          handleKind = .email
                      default:
                          handleKind = .custom
                      }

                      let handle = CommunicationHandle(value: handleValue, kind: handleKind)

                      // Optional display name
                      var nameComponents: PersonNameComponents? = nil
                      if let displayName = contactDict["displayName"] as? String {
                          var components = PersonNameComponents()
                          components.nickname = displayName
                          nameComponents = components
                      }

                      let personInfo = PersonInformation(handle: handle, nameComponents: nameComponents)
                      personInfoList.append(personInfo)
                  }

                  guard !personInfoList.isEmpty else {
                      reject("ERR_IOS_COMM_PERMISSION", "No valid contacts provided", nil)
                      return
                  }

                  // Parse actions
                  var communicationActions: Set<CommunicationTopic.Action> = []
                  for action in actions {
                      if let actionStr = action as? String {
                          switch actionStr {
                          case "message":
                              communicationActions.insert(.message)
                          case "call":
                              communicationActions.insert(.call)
                          case "video":
                              communicationActions.insert(.video)
                          default:
                              break
                          }
                      }
                  }

                  // Default to message if no actions specified
                  if communicationActions.isEmpty {
                      communicationActions.insert(.message)
                  }

                  var topic = CommunicationTopic(personInformation: personInfoList)
                  topic.actions = communicationActions

                  var question = PermissionQuestion(communicationTopic: topic)

                  try await CommunicationLimits.current.ask(question, in: viewController)

                  // If we get here without error, the request was shown successfully
                  let resultMap: [String: Any?] = [
                      "granted": true,
                      "error": nil
                  ]
                  resolve(resultMap)

              } catch {
                  var errorMsg = error.localizedDescription
                  if errorMsg.contains("region") {
                      errorMsg += ". (Hint: User may be in a region that does not support this feature.)"
                  } else if errorMsg.contains("Family Sharing") || errorMsg.contains("Communication Limits") {
                      errorMsg += ". (Hint: Family Sharing and Communication Limits must be enabled.)"
                  }
                  reject("ERR_IOS_COMM_PERMISSION", errorMsg, error)
              }
          }
      } else {
          resolve(["granted": false, "error": "Requires iOS 26.2+"])
      }
      #else
      resolve(["granted": false, "error": "PermissionKit SDK not available"])
      #endif
  }

  @objc
  public func getKnownCommunicationHandles(
    handles: NSArray,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
      #if compiler(>=6.0) && canImport(PermissionKit)
      if #available(iOS 26.2, *) {
          Task {
              do {
                  // Parse handles from JS
                  var communicationHandles: Set<CommunicationHandle> = []
                  for handle in handles {
                      guard let handleDict = handle as? [String: Any],
                            let handleValue = handleDict["handle"] as? String,
                            let handleKindStr = handleDict["handleKind"] as? String else {
                          continue
                      }

                      let handleKind: CommunicationHandle.Kind
                      switch handleKindStr {
                      case "phoneNumber":
                          handleKind = .phoneNumber
                      case "email":
                          handleKind = .email
                      default:
                          handleKind = .custom
                      }

                      let commHandle = CommunicationHandle(value: handleValue, kind: handleKind)
                      communicationHandles.insert(commHandle)
                  }

                  guard !communicationHandles.isEmpty else {
                      reject("ERR_IOS_KNOWN_HANDLES", "No valid handles provided", nil)
                      return
                  }

                  let knownHandles = await CommunicationLimits.current.knownHandles(in: communicationHandles)

                  // Convert back to string array for JS
                  let knownHandleValues = knownHandles.map { $0.value }

                  let resultMap: [String: Any?] = [
                      "knownHandles": knownHandleValues,
                      "error": nil
                  ]
                  resolve(resultMap)

              } catch {
                  reject("ERR_IOS_KNOWN_HANDLES", error.localizedDescription, error)
              }
          }
      } else {
          resolve(["knownHandles": [], "error": "Requires iOS 26.2+"])
      }
      #else
      resolve(["knownHandles": [], "error": "PermissionKit SDK not available"])
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
