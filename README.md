# cordova-plugin-apple-age-check

iOS plugin for **Apple's Declared Age Range API** (iOS 26+).

This plugin provides a simple Cordova interface to request the user's declared age range on iOS.

## Features

- Uses Apple's official `DeclaredAgeRange` framework
- Returns normalized result format (consistent with Android version)
- Includes `isSupported()` check
- Lightweight and async-friendly

## Requirements

- Cordova iOS platform ≥ 7.0.0
- iOS 26 or later
- The entitlement **`com.apple.developer.declared-age-range`** must be enabled in your Xcode project


## Installation

```bash
cordova plugin add @globules-io/cordova-plugin-apple-age-check
cordova plugin rm @globules-io/cordova-plugin-apple-age-check
```
## Supported Platforms

iOS (26+)

## JS API
```bash
AgeCheckPlugin.checkAge(
    function(result) {
        console.log("Apple Age Check Result:", result);

        if (result.userStatus === "DECLARED") {
            console.log(`Age range: ${result.ageLower} - ${result.ageUpper}`);
            // Grant appropriate access based on age
        } 
        else if (result.userStatus === "DECLINED") {
            // User declined to share age → apply restricted experience
        }
    },
    function(error) {
        console.error("Age check failed:", error);
    }
);

AgeCheckPlugin.isSupported(function(supported) {
    console.log("Declared Age Range API supported:", supported);
});
```
