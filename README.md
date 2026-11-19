# cordova-plugin-apple-age-check

Cordova plugin for Apple's Declared Age Range API on iOS.

https://developer.apple.com/documentation/declaredagerange

`checkAge()` calls `AgeRangeService.requestAgeRange(ageGates:in:)`. The system sheet asks the person, or a parent in a Family Sharing group, to share an age band. The band is cut at the age gates you pass.

Build with the iOS 26.5 SDK or later so the `confirmed` declaration is included. The call runs on iOS 26 and later. `isEligibleForAgeFeatures()` needs iOS 26.2.

The plugin adds the `com.apple.developer.declared-age-range` entitlement and weakly links `DeclaredAgeRange`. The app's App ID still needs the Declared Age Range capability in its provisioning profile.

### Add the plugin

> cordova plugin add @globules-io/cordova-plugin-apple-age-check

### Remove the plugin

> cordova plugin rm @globules-io/cordova-plugin-apple-age-check

### Usage

```javascript
AgeCheckPlugin.checkAge([13, 16, 18],
    function(result) {
        if (result.sharingStatus !== 'SHARING') {
            // The person declined. In some regulated regions the system shares anyway.
            return;
        }

        // ageLower is null below the lowest gate.
        // ageUpper is null at or above the highest gate.
        console.log(result.ageLower, result.ageUpper, result.ageRangeDeclaration);
    },
    function(error) {
        console.error(error.code, error.message);
    }
);

AgeCheckPlugin.isSupported(function(supported) {
    console.log(supported);
});

AgeCheckPlugin.isEligibleForAgeFeatures(function(eligible) {
    console.log(eligible);
}, function(error) {
    console.error(error.code, error.message);
});
```

`checkAge(success, error)` uses a single gate of 18. `checkAge(16, success, error)` uses that one gate.

Pass 1 to 3 gates. Each later gate must be at least 2 years above the one before it.

## Response

`checkAge` resolves when the person shares or declines. It rejects when the request fails.

| Field | Values |
| --- | --- |
| `sharingStatus` | `SHARING`, `DECLINED` |
| `ageLower` | Inclusive lower bound, or `null` when the person is below the lowest gate |
| `ageUpper` | Inclusive upper bound, or `null` when the person is at or above the highest gate |
| `ageRangeDeclaration` | How the band was set, or `null` |
| `activeParentalControls` | Array of control names. Empty when none are shared |

`ageLower`, `ageUpper`, and `ageRangeDeclaration` are `null` when `sharingStatus` is `DECLINED`.

### ageRangeDeclaration

#### SELF_DECLARED

The person set the band on their Apple Account.

#### GUARDIAN_DECLARED

A parent, guardian, or Family Organizer set the band.

#### CONFIRMED

The band was confirmed. On iOS 26.5 and later this replaces the method-specific values below.

#### PAYMENT_CHECKED

The person confirmed with a payment method. Not returned on iOS 26.5 and later.

#### GOVERNMENT_ID_CHECKED

The person confirmed with a government ID. Not returned on iOS 26.5 and later.

#### CHECKED_BY_OTHER_METHOD

The person confirmed with another method. Not returned on iOS 26.5 and later.

#### GUARDIAN_PAYMENT_CHECKED

A parent or guardian confirmed with a payment method.

#### GUARDIAN_GOVERNMENT_ID_CHECKED

A parent or guardian confirmed with a government ID.

#### GUARDIAN_CHECKED_BY_OTHER_METHOD

A parent or guardian confirmed with another method.

### activeParentalControls

#### COMMUNICATION_LIMITS

Screen Time communication limits are on.

#### SIGNIFICANT_APP_CHANGE_APPROVAL_REQUIRED

An older signal that a significant app change needs parental approval. Prefer `isEligibleForAgeFeatures()` and Apple's significant-update APIs for that flow. This plugin does not present the significant-update sheet.

## Error object

```javascript
{
    "code": "NOT_AVAILABLE",
    "message": "..."
}
```

| Code | Meaning |
| --- | --- |
| `NOT_AVAILABLE` | The system could not share an age range. |
| `INVALID_REQUEST` | The gates or the request configuration were rejected. |
| `DECLINED_ONBOARDING` | The person declined age-range onboarding. |
| `INVALID_ACCOUNT` | This Apple Account cannot share an age range. |
| `NETWORK` | A network or server failure. |
| `INVALID_AGE_GATES` | The gates were missing, out of range, or less than 2 years apart. |
| `NO_VIEW_CONTROLLER` | There is no Cordova view controller to present the sheet. |
| `UNSUPPORTED` | This iOS version does not have the called API. |
| `UNKNOWN` | Any other failure. |

## Eligibility

`isSupported()` is true on iOS 26 and later. It does not ask the person anything.

`isEligibleForAgeFeatures()` is true when this person is in a region that requires age assurance. It needs iOS 26.2. On macOS, Apple returns false. A regulated region can share the band without a decline option.
