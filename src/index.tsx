import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package '@milkinteractive/react-native-age-range' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const StoreAgeSignalsNativeModules = NativeModules.StoreAgeSignalsNativeModules
  ? NativeModules.StoreAgeSignalsNativeModules
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

// Android Types

/**
 * User verification status from Google Play Age Signals API.
 * - OVER_AGE: User is verified as an adult (18+)
 * - UNDER_AGE: User has a supervised account (child/teen)
 * - UNDER_AGE_APPROVAL_PENDING: Supervised user, parent hasn't approved pending significant changes
 * - UNDER_AGE_APPROVAL_DENIED: Supervised user, parent denied approval for significant changes
 * - UNKNOWN: Status could not be determined
 */
export type AndroidUserStatus =
  | 'OVER_AGE'
  | 'UNDER_AGE'
  | 'UNDER_AGE_APPROVAL_PENDING'
  | 'UNDER_AGE_APPROVAL_DENIED'
  | 'UNKNOWN';

export interface PlayAgeRangeStatusResult {
  installId: string | null;
  userStatus: AndroidUserStatus | null;
  error: string | null;
  /**
   * The (inclusive) lower bound of a supervised user's age range.
   * 0 to 18.
   */
  ageLower?: number | null;
  /**
   * The (inclusive) upper bound of a supervised user's age range.
   * 2 to 18.
   */
  ageUpper?: number | null;
  /**
   * The effective from date of the most recent significant change that was approved.
   * ISO string format.
   */
  mostRecentApprovalDate?: string | null;
  /**
   * The numerical error code if the request failed.
   * e.g., -1 (API_NOT_AVAILABLE), -2 (PLAY_STORE_NOT_FOUND), etc.
   */
  errorCode?: number | null;
}

// iOS Types

/**
 * How the age range was declared/verified.
 * - selfDeclared: User declared their own age
 * - guardianDeclared: Guardian set the age (for children in iCloud family)
 * - checkedByOtherMethod: Verified by another method
 * - guardianCheckedByOtherMethod: Guardian verified by another method
 * - governmentIDChecked: Verified via government ID
 * - guardianGovernmentIDChecked: Guardian verified via government ID
 * - paymentChecked: Verified via payment method (credit card)
 * - guardianPaymentChecked: Guardian verified via payment method
 */
export type AgeRangeDeclarationType =
  | 'selfDeclared'
  | 'guardianDeclared'
  | 'checkedByOtherMethod'
  | 'guardianCheckedByOtherMethod'
  | 'governmentIDChecked'
  | 'guardianGovernmentIDChecked'
  | 'paymentChecked'
  | 'guardianPaymentChecked'
  | 'unknown';

/**
 * Parental control settings active for the user.
 */
export interface ParentalControlsInfo {
  /** Whether communication limits are enabled (e.g., contact restrictions) */
  communicationLimits?: boolean;
  /** Whether significant app changes require parental approval */
  significantAppChangeApprovalRequired?: boolean;
}

export interface DeclaredAgeRangeResult {
  status: 'sharing' | 'declined' | null;
  lowerBound: number | null;
  upperBound: number | null;
  /**
   * How the age range was declared/verified (iOS 26+).
   * For children: always 'guardianDeclared'
   * For teens in iCloud family: 'guardianDeclared'
   * For teens not in family: 'selfDeclared'
   * For adults: 'selfDeclared'
   */
  ageRangeDeclaration?: AgeRangeDeclarationType | null;
  /**
   * Parental control settings active for the user (if under age of majority).
   */
  parentalControls?: ParentalControlsInfo | null;
  error: string | null;
}

// Eligibility Result
export interface DeclaredAgeEligibilityResult {
  isEligible: boolean;
  error: string | null;
}

// ========== PERMISSIONKIT TYPES (iOS 26+) ==========

/**
 * Status of significant change approval request.
 * - approved: Parent/guardian approved the change
 * - denied: Parent/guardian denied the change
 * - pending: Request has been sent, awaiting response
 */
export type SignificantChangeStatus = 'approved' | 'denied' | 'pending' | null;

/**
 * Result of significant change approval request.
 */
export interface SignificantChangeResult {
  status: SignificantChangeStatus;
  error: string | null;
}

/**
 * Handle type for communication contacts.
 * - phoneNumber: Phone number identifier
 * - email: Email address identifier
 * - custom: Custom identifier (username, handle, etc.)
 */
export type CommunicationHandleKind = 'phoneNumber' | 'email' | 'custom';

/**
 * Contact information for communication permission request.
 */
export interface CommunicationContact {
  /** Unique identifier (phone, email, username) */
  handle: string;
  /** Type of handle */
  handleKind: CommunicationHandleKind;
  /** Optional display name shown to parent/guardian */
  displayName?: string;
}

/**
 * Communication actions that can be requested.
 * - message: Text/chat messaging
 * - call: Voice calls
 * - video: Video calls
 */
export type CommunicationAction = 'message' | 'call' | 'video';

/**
 * Result of communication permission request.
 */
export interface CommunicationPermissionResult {
  /** Whether the permission request was successfully shown */
  granted: boolean;
  error: string | null;
}

/**
 * Result of known handles check.
 */
export interface KnownHandlesResult {
  /** Handles that are recognized by the system (known contacts) */
  knownHandles: string[];
  error: string | null;
}

export interface AndroidAgeRangeConfig {
  /**
   * Enable mock mode to simulate results without calling Google Play API.
   * Useful for development and testing.
   */
  isMock?: boolean;
  /**
   * The status to return when isMock is true.
   * Default: 'OVER_AGE'
   */
  mockStatus?: AndroidUserStatus;
  /**
   * (Mock Only) Lower bound of the age range (e.g. 13).
   * Relevant when mockStatus is 'UNDER_AGE' (Supervised).
   */
  mockAgeLower?: number;
  /**
   * (Mock Only) Upper bound of the age range (e.g. 17).
   * Relevant when mockStatus is 'UNDER_AGE' (Supervised).
   */
  mockAgeUpper?: number;
  /**
   * (Mock Only) The numerical error code to throw.
   * e.g., -1 for API_NOT_AVAILABLE.
   */
  mockErrorCode?: number;
  /**
   * (Mock Only) ISO date string for most recent approval.
   */
  mockMostRecentApprovalDate?: string;
}

/**
 * Retrieves the age range declaration status from Google Play's Age Signals API.
 * @platform android
 */
export function getAndroidPlayAgeRangeStatus(
  config?: AndroidAgeRangeConfig
): Promise<PlayAgeRangeStatusResult> {
  if (Platform.OS !== 'android') {
    return Promise.resolve({
      installId: null,
      userStatus: null,
      error: 'This method is only available on Android',
    });
  }
  return StoreAgeSignalsNativeModules.getAndroidPlayAgeRangeStatus(
    config || {}
  );
}

// Minimum iOS version required for DeclaredAgeRange API
const IOS_MIN_VERSION_DECLARED_AGE_RANGE = 26.0;

/**
 * Requests age range declaration from iOS Declared Age Range API.
 * @platform ios
 * @param firstThresholdAge First age threshold (required, e.g., 13)
 * @param secondThresholdAge Second age threshold (optional, e.g., 17)
 * @param thirdThresholdAge Third age threshold (optional, e.g., 21)
 * @remarks Requires iOS 26.0+. Returns error on older iOS versions.
 */
export function requestIOSDeclaredAgeRange(
  firstThresholdAge: number,
  secondThresholdAge?: number,
  thirdThresholdAge?: number
): Promise<DeclaredAgeRangeResult> {
  if (Platform.OS !== 'ios') {
    return Promise.resolve({
      status: null,
      lowerBound: null,
      upperBound: null,
      ageRangeDeclaration: null,
      parentalControls: null,
      error: 'This method is only available on iOS',
    });
  }

  // Early return for iOS versions below 26 to prevent native bridge errors
  const iosVersion = parseFloat(String(Platform.Version));
  if (iosVersion < IOS_MIN_VERSION_DECLARED_AGE_RANGE) {
    return Promise.resolve({
      status: null,
      lowerBound: null,
      upperBound: null,
      ageRangeDeclaration: null,
      parentalControls: null,
      error: `Requires iOS ${IOS_MIN_VERSION_DECLARED_AGE_RANGE}.0+. Current version: iOS ${iosVersion}`,
    });
  }

  return StoreAgeSignalsNativeModules.requestIOSDeclaredAgeRange(
    firstThresholdAge,
    secondThresholdAge ?? null,
    thirdThresholdAge ?? null
  );
}

// Minimum iOS version required for isEligibleForAgeFeatures API
const IOS_MIN_VERSION_ELIGIBLE_CHECK = 26.2;

/**
 * Checks if the current user is eligible for age verification features on iOS.
 * This determines if age checks need to be applied (e.g., user is in an applicable region like Texas).
 * @platform ios
 * @returns Promise<DeclaredAgeEligibilityResult> - Object containing isEligible boolean and error string
 * @remarks Requires iOS 26.2+. Returns isEligible: false with error message if not available.
 */
export function isIOSEligibleForAgeFeatures(): Promise<DeclaredAgeEligibilityResult> {
  if (Platform.OS !== 'ios') {
    return Promise.resolve({
      isEligible: false,
      error: 'This method is only available on iOS',
    });
  }

  // Early return for iOS versions below 26 to prevent native bridge errors
  const iosVersion = parseFloat(String(Platform.Version));
  if (iosVersion < IOS_MIN_VERSION_ELIGIBLE_CHECK) {
    return Promise.resolve({
      isEligible: false,
      error: `Requires iOS ${IOS_MIN_VERSION_ELIGIBLE_CHECK}.0+. Current version: iOS ${iosVersion}`,
    });
  }

  return StoreAgeSignalsNativeModules.isEligibleForAgeFeatures();
}

/**
 * Checks if the current user is eligible for age verification features on Android.
 * This determines if age checks need to be applied (e.g., user is in an applicable region like Texas, Utah, Louisiana).
 * @platform android
 * @returns Promise<DeclaredAgeEligibilityResult> - Object containing isEligible boolean and error string
 * @remarks Makes a lightweight API call to determine eligibility. Returns isEligible: false with error message if not available.
 */
export function isAndroidEligibleForAgeFeatures(): Promise<DeclaredAgeEligibilityResult> {
  if (Platform.OS !== 'android') {
    return Promise.resolve({
      isEligible: false,
      error: 'This method is only available on Android',
    });
  }
  return StoreAgeSignalsNativeModules.isEligibleForAgeFeatures();
}

// ========== PERMISSIONKIT FUNCTIONS (iOS 26.2+) ==========

// Minimum iOS version required for PermissionKit APIs
const IOS_MIN_VERSION_PERMISSIONKIT = 26.2;

/**
 * Requests parental approval for significant app changes (iOS PermissionKit).
 *
 * Use this when `parentalControls.significantAppChangeApprovalRequired` is `true`
 * from the `requestIOSDeclaredAgeRange()` response.
 *
 * This shows a system dialog to request parental consent for significant app updates.
 * The parent/guardian will receive a notification via Messages.
 *
 * @platform ios
 * @requires iOS 26.2+
 * @returns Promise<SignificantChangeResult> - Contains status ('pending', 'approved', 'denied') and error
 *
 * @example
 * ```typescript
 * const ageResult = await requestIOSDeclaredAgeRange(13, 17, 21);
 * if (ageResult.parentalControls?.significantAppChangeApprovalRequired) {
 *   const result = await requestIOSSignificantChangeApproval();
 *   if (result.status === 'pending') {
 *     // Request sent, await parent response
 *   }
 * }
 * ```
 */

export function requestIOSSignificantChangeApproval(): Promise<SignificantChangeResult> {
  if (Platform.OS !== 'ios') {
    return Promise.resolve({
      status: null,
      error: 'This method is only available on iOS',
    });
  }

  const iosVersion = parseFloat(String(Platform.Version));
  if (iosVersion < IOS_MIN_VERSION_PERMISSIONKIT) {
    return Promise.resolve({
      status: null,
      error: `Requires iOS ${IOS_MIN_VERSION_PERMISSIONKIT}+. Current version: iOS ${iosVersion}`,
    });
  }

  return StoreAgeSignalsNativeModules.requestSignificantChangeApproval();
}

/**
 * Requests permission for a child to communicate with specified contacts (iOS PermissionKit).
 *
 * Use this when `parentalControls.communicationLimits` is `true`
 * from the `requestIOSDeclaredAgeRange()` response.
 *
 * This shows a system dialog requesting the parent/guardian to approve
 * communication with the specified contacts. The request is sent via Messages.
 *
 * @platform ios
 * @requires iOS 26.2+
 * @param contacts - Array of contacts to request permission for
 * @param actions - Optional array of communication actions (defaults to ['message'])
 * @returns Promise<CommunicationPermissionResult> - Contains granted boolean and error
 *
 * @example
 * ```typescript
 * const ageResult = await requestIOSDeclaredAgeRange(13, 17, 21);
 * if (ageResult.parentalControls?.communicationLimits) {
 *   const result = await requestIOSCommunicationPermission(
 *     [{ handle: 'friend@example.com', handleKind: 'email', displayName: 'School Friend' }],
 *     ['message', 'call']
 *   );
 * }
 * ```
 */
export function requestIOSCommunicationPermission(
  contacts: CommunicationContact[],
  actions?: CommunicationAction[]
): Promise<CommunicationPermissionResult> {
  if (Platform.OS !== 'ios') {
    return Promise.resolve({
      granted: false,
      error: 'This method is only available on iOS',
    });
  }

  const iosVersion = parseFloat(String(Platform.Version));
  if (iosVersion < IOS_MIN_VERSION_PERMISSIONKIT) {
    return Promise.resolve({
      granted: false,
      error: `Requires iOS ${IOS_MIN_VERSION_PERMISSIONKIT}+. Current version: iOS ${iosVersion}`,
    });
  }

  return StoreAgeSignalsNativeModules.requestCommunicationPermission(
    contacts,
    actions || ['message']
  );
}

/**
 * Checks which handles are recognized by the system (known contacts) (iOS PermissionKit).
 *
 * Use this to determine which contacts are already approved before showing
 * a communication permission request.
 *
 * @platform ios
 * @requires iOS 26.2+
 * @param handles - Array of handles to check
 * @returns Promise<KnownHandlesResult> - Contains array of known handle values and error
 *
 * @example
 * ```typescript
 * const result = await getIOSKnownCommunicationHandles([
 *   { handle: 'user@example.com', handleKind: 'email' },
 *   { handle: 'gamer123', handleKind: 'custom' }
 * ]);
 *
 * const unknownContacts = handles.filter(
 *   h => !result.knownHandles.includes(h.handle)
 * );
 *
 * if (unknownContacts.length > 0) {
 *   // Request permission for unknown contacts
 *   await requestIOSCommunicationPermission(unknownContacts);
 * }
 * ```
 */
export function getIOSKnownCommunicationHandles(
  handles: CommunicationContact[]
): Promise<KnownHandlesResult> {
  if (Platform.OS !== 'ios') {
    return Promise.resolve({
      knownHandles: [],
      error: 'This method is only available on iOS',
    });
  }

  const iosVersion = parseFloat(String(Platform.Version));
  if (iosVersion < IOS_MIN_VERSION_PERMISSIONKIT) {
    return Promise.resolve({
      knownHandles: [],
      error: `Requires iOS ${IOS_MIN_VERSION_PERMISSIONKIT}+. Current version: iOS ${iosVersion}`,
    });
  }

  return StoreAgeSignalsNativeModules.getKnownCommunicationHandles(handles);
}
