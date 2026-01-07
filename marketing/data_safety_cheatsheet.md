# Google Play Data Safety Form - Cheatsheet

**App**: Angry Battery
**Version**: 1.0

When filling out the "Data Safety" form in the Google Play Console, use these answers based on the current codebase.

## 1. Data Collection & Security
*   **Does your app collect or share any of the required user data types?** -> **Yes**
*   **Is all of the user data collected by your app encrypted in transit?** -> **Yes** (Standard Android HTTPS/TLS is used for any network calls, though we mostly run local).
*   **Do you provide a way for users to request that their data be deleted?** -> **No** (Data is local-only, clearing storage deletes it).

## 2. Data Types

### Device or other IDs
*   **Data Type**: Device or other identifiers (if ad SDKs or analytics are present, otherwise No).
    *   *Audit*: We use `battery_plus`, `android_intent_plus`. We do NOT use AdMob or Firebase Analytics in the visible code.
    *   *Answer*: **No** (unless you add Ads/Analytics later).

### App Info and Performance
*   **Data Type**: Crash logs, Diagnostics.
    *   *Audit*: We do not have Crashlytics/Sentry installed.
    *   *Answer*: **No**.

### App Activity
*   **Data Type**: Installed apps.
    *   *Audit*: **YES**. We access `UsageStats` to see other running apps (Vampire Hunter).
    *   *Selection*: **Installed Apps**.
    *   *Collection*: **Yes**.
    *   *Sharing*: **No** (Processed locally).
    *   *Purposes*: **App functionality** (Vampire Hunter).
    *   *Ephemeral?*: **Yes** (We only store the "Suspects" temporarily/locally).

### Location
*   **Data Type**: Precise/Approximate Location.
    *   *Audit*: We might have permissions in `AndroidManifest.xml` via transitive dependencies (e.g. WiFi scanning often requires location), but we don't explicitly track user location.
    *   *Answer*: **No**, unless required by a specific ad network (none present).

## Summary Table

| Data Type | Collected? | Shared? | Purpose |
| :--- | :--- | :--- | :--- |
| **Installed Apps** | Yes | No | App Functionality (Battery monitoring) |
| **App Activity** | Yes | No | App Functionality (Usage stats) |

> [!NOTE]
> This app is primarily **Local-First**. We process data on-device. We do not send it to a server. This simplifies the form significantly. The "Collected" definition usually implies "sent off device", but "processed ephemerally" is also a form of collection. Since we display it to the user and store it in SharedPreferences, marking it as "Collected" but "Not Shared" is the safest and most honest approach.
