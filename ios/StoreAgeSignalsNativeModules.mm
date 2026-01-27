#import "StoreAgeSignalsNativeModules.h"
#import <React/RCTBridgeModule.h>
#if __has_include("react_native_store_age_signals_native_modules-Swift.h")
#import "react_native_store_age_signals_native_modules-Swift.h"
#else
#import "StoreAgeSignalsNativeModules-Swift.h"
#endif

@interface StoreAgeSignalsNativeModules ()
@property(nonatomic, strong) StoreAgeSignalsNativeModulesSwift *swiftImpl;
@end

@implementation StoreAgeSignalsNativeModules

RCT_EXPORT_MODULE()

- (instancetype)init {
  if (self = [super init]) {
    // Assuming StoreAgeSignalsNativeModulesSwift is a Swift class that will be
    // bridged You might need to import the Swift bridging header if not already
    // done. e.g., #import "YOUR_PRODUCT_MODULE_NAME-Swift.h"
    _swiftImpl = [[StoreAgeSignalsNativeModulesSwift alloc] init];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup {
  return YES; // UI Required
}

RCT_EXPORT_METHOD(getAndroidPlayAgeRangeStatus : (RCTPromiseResolveBlock)
                      resolve reject : (RCTPromiseRejectBlock)reject) {
  NSDictionary *result = @{
    @"installId" : [NSNull null],
    @"userStatus" : [NSNull null],
    @"error" : @"This method is only available on Android. Use "
               @"requestIOSDeclaredAgeRange on iOS."
  };
  resolve(result);
}

RCT_EXPORT_METHOD(requestIOSDeclaredAgeRange : (nonnull NSNumber *)firstThresholdAge
                      secondThresholdAge : (NSNumber *)secondThresholdAge
                      thirdThresholdAge : (NSNumber *)thirdThresholdAge
                      resolve : (RCTPromiseResolveBlock)resolve
                      reject : (RCTPromiseRejectBlock)reject) {
  // Convert NSNumber to NSNumber (handling nil for optional params)
  // Swift side expects NSNumber which can represent nil via NSNull
  [_swiftImpl
      requestIOSDeclaredAgeRangeWithFirstThresholdAge:firstThresholdAge
                                   secondThresholdAge:secondThresholdAge
                                    thirdThresholdAge:thirdThresholdAge
                                              resolve:resolve
                                               reject:reject];
}

RCT_EXPORT_METHOD(isEligibleForAgeFeatures : (RCTPromiseResolveBlock)
                      resolve reject : (RCTPromiseRejectBlock)reject) {
  [_swiftImpl isEligibleForAgeFeaturesWithResolve:resolve reject:reject];
}

// Don't compile this code when we build for the old architecture.
// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
// Legacy module: TurboModule spec not generated/configured.
// - (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
//     (const facebook::react::ObjCTurboModule::InitParams &)params {
//   return std::make_shared<
//       facebook::react::NativeStoreAgeSignalsNativeModulesSpecJSI>(params);
// }
#endif

@end
