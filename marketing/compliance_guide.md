# Angry Battery: 2026 Critical Compliance Checklist

## 1. The "Red Label" Warning (New for March 2026)
Google now penalizes apps that use excessive background power. If your app stays awake (using "wake locks") for more than 2 hours in a 24-hour period, Google will put a red warning label on your Play Store listing saying: "This app may use more battery than expected."

**Action:** Ensure your "Angry Battery" app is extremely efficient. Use the Android Vitals dashboard in your Play Console to monitor this.

## 2. The "Usage Access" Prominent Disclosure
Because you are accessing other apps' usage data, you cannot just put it in the Privacy Policy. You must show a full-screen pop-up the first time the user opens the app that says:

> "Angry Battery needs Usage Access to see which apps are draining your battery. This data is processed locally and never leaves your device. [Accept] [Decline]"

## 3. Where to Host Your Policy
Google requires a public URL. You have three good options:
*   GitHub Pages: Free and professional for developers.
*   App-Privacy-Policy.com: A generator that hosts it for you.
*   Your own website: (e.g., angrybatteryapp.com/privacy).

## 4. Play Store "Data Safety" Section
When you upload the app, you’ll have to fill out a "Data Safety" form manually. For a battery app, you should select:
*   **Data Collection:** "Yes" (for Usage Data).
*   **Data Shared:** "No" (unless you use ads or analytics).
*   **Security:** "Data is encrypted in transit" and "Users can request data deletion."
