var exec = require('cordova/exec');
var AgeCheckPlugin = {};
/**
 * Check the user's age verification status using Apple's Declared Age Range API.
 *
 * @param {function} successCallback - Called with result object on success
 * @param {function} errorCallback   - Called with error on failure
 *
 * Result object example:
 * {
 *   "userStatus": "DECLARED" | "DECLINED" | null,
 *   "ageLower": number | null,
 *   "ageUpper": number | null,
 *   "mostRecentApprovalDate": null,     // Not available on iOS
 *   "installId": null                   // Not available on iOS
 * }
 */
AgeCheckPlugin.checkAge = function(successCallback, errorCallback) {
    if (typeof successCallback !== 'function') {
        console.warn('AgeCheckPlugin.checkAge: successCallback must be a function');
        return;
    }
    if (typeof errorCallback !== 'function') {
        errorCallback = function(err) {
            console.error('AgeCheckPlugin.checkAge error:', err);
        };
    }
    exec(
        successCallback,
        errorCallback,
        'AgeCheck',         
        'checkAge',        
        []
    );
};

/**
 * Check if the Declared Age Range API is supported on this device.
 *
 * @param {function} successCallback - Called with boolean (true/false)
 * @param {function} errorCallback   - Optional
 */
AgeCheckPlugin.isSupported = function(successCallback, errorCallback) {
    if (typeof successCallback !== 'function') {
        return;
    }

    if (typeof errorCallback !== 'function') {
        errorCallback = function() {};
    }

    exec(
        successCallback,
        errorCallback,
        'AgeCheck',
        'isSupported',
        []
    );
};
module.exports = AgeCheckPlugin;