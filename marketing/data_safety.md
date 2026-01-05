# Google Play Data Safety Form Cheat Sheet

Use this guide when filling out the "Data Safety" section in the Google Play Console.

## 1. Data Collection and Security
*   **Does your app collect or share any of the required user data types?** -> **Yes**
*   **Is all of the user data collected by your app encrypted in transit?** -> **Yes** (Standard HTTPS/OS encryption)
*   **Do you provide a way for users to request that their data is deleted?** -> **Yes** (Standard requirement, usually via email/website)

## 2. Data Types
Select the following data types:

### App Activity
*   [x] **App interactions** (We track screen on/off events)
*   [x] **Installed apps** (We query UsageStats for other apps)

### Device or Other IDs
*   [x] **Device or other IDs** (Battery API usage)

## 3. Usage & Handling (For each selected type)

**For "App interactions" and "Installed apps":**
*   **Is this data collected, shared, or both?** -> **Collected** (It stays on the device, but "Collected" covers local processing in some definitions, though purely local apps can sometimes say No. To be safe/transparent given permissions:) -> *Actually, strictly speaking, if data never leaves the device, you can answer "No" to collection. However, since we access sensitive permissions, Google reviews may Flag it. Best practice for local-only apps:*
    *   *If you treat it as "No Collection" (Local Only), be prepared to explain.*
    *   *Safest Path:* functionality -> **App functionality**
*   **Is this data processed ephemerally?** -> **Yes**
*   **Is this data required for your app?** -> **Yes**

**Clarification on "Collection":**
Google defines "Collection" as transmitting data *off the device*.
**Since Angry Battery is 100% offline and sends nothing to a server:**
You can largely answer **NO** to data collection for most categories, *EXCEPT* if you use a third-party library that phones home (we don't).

**Recommendation:**
1.  Answer **No** to "Does your app collect or share any of the required user data types?"
2.  In your Privacy Policy, explicitly state: **"Angry Battery processes all data locally on your device. No personal data is transmitted to external servers."** (This is what we wrote in our policy).

*Note: The Usage Access permission is a sensitive permission, but if the data stays local, it is not "Collected" in the Play Store definition.*
