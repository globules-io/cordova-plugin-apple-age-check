var exec = require('cordova/exec');

var AgeCheckPlugin = {};

/**
 * Ask the system to share an age range.
 *
 * Age gates are the thresholds that cut the range. Pass one number, or up to
 * three numbers at least two years apart. Omitting them uses 18.
 *
 * A declined share is a successful result with sharingStatus "DECLINED".
 *
 * Result:
 * {
 *   sharingStatus: "SHARING" | "DECLINED",
 *   ageLower: number | null,
 *   ageUpper: number | null,
 *   ageRangeDeclaration: "SELF_DECLARED" | "GUARDIAN_DECLARED" | "CONFIRMED" |
 *       "PAYMENT_CHECKED" | "GOVERNMENT_ID_CHECKED" | "CHECKED_BY_OTHER_METHOD" |
 *       "GUARDIAN_PAYMENT_CHECKED" | "GUARDIAN_GOVERNMENT_ID_CHECKED" |
 *       "GUARDIAN_CHECKED_BY_OTHER_METHOD" | "UNKNOWN" | null,
 *   activeParentalControls: string[]
 * }
 *
 * ageLower is null when the person is below the lowest gate.
 * ageUpper is null when the person is at or above the highest gate.
 */
AgeCheckPlugin.checkAge = function(ageGates, successCallback, errorCallback) {
    if (typeof ageGates === 'function') {
        errorCallback = successCallback;
        successCallback = ageGates;
        ageGates = [18];
    } else if (typeof ageGates === 'number') {
        ageGates = [ageGates];
    }

    if (typeof successCallback !== 'function') {
        console.warn('AgeCheckPlugin.checkAge: successCallback must be a function');
        return;
    }
    if (typeof errorCallback !== 'function') {
        errorCallback = function(err) {
            console.error('AgeCheckPlugin.checkAge error:', err);
        };
    }
    if (!Array.isArray(ageGates) || ageGates.length < 1 || ageGates.length > 3) {
        errorCallback({
            code: 'INVALID_AGE_GATES',
            message: 'Pass 1 to 3 age gates.'
        });
        return;
    }

    exec(successCallback, errorCallback, 'AgeCheck', 'checkAge', [ageGates]);
};

/**
 * True when this device can call Declared Age Range (iOS 26 or later).
 */
AgeCheckPlugin.isSupported = function(successCallback, errorCallback) {
    if (typeof successCallback !== 'function') {
        return;
    }
    if (typeof errorCallback !== 'function') {
        errorCallback = function() {};
    }
    exec(successCallback, errorCallback, 'AgeCheck', 'isSupported', []);
};

/**
 * True when this person is in a region that requires age assurance.
 * Requires iOS 26.2. This does not ask the person to share an age range.
 */
AgeCheckPlugin.isEligibleForAgeFeatures = function(successCallback, errorCallback) {
    if (typeof successCallback !== 'function') {
        console.warn('AgeCheckPlugin.isEligibleForAgeFeatures: successCallback must be a function');
        return;
    }
    if (typeof errorCallback !== 'function') {
        errorCallback = function(err) {
            console.error('AgeCheckPlugin.isEligibleForAgeFeatures error:', err);
        };
    }
    exec(successCallback, errorCallback, 'AgeCheck', 'isEligibleForAgeFeatures', []);
};

module.exports = AgeCheckPlugin;
