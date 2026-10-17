# Firebase Analytics DebugView Verification Guide

This guide explains how to enable Firebase DebugView on your Android test device or emulator, verify events in near-real-time via the Firebase Console, and confirm compliance with the hiring assessment specifications.

---

## 1. Tracked Events & Payload Specification

Per the specification, only non-PII parameters are logged:

| Event Name | Trigger Condition | Parameters |
| :--- | :--- | :--- |
| `login_success` | Helper signs in successfully | `{"method": "password"}` |
| `job_viewed` | Helper opens a job details screen | `{"job_id": 1, "status": "ASSIGNED"}` |
| `job_status_updated` | Job status is successfully changed via API | `{"job_id": 1, "from_status": "ASSIGNED", "to_status": "IN_PROGRESS"}` |

> [!NOTE]
> Privacy Compliance: In accordance with data privacy guidelines, zero personal identifiers (no usernames, real names, or customer addresses) are dispatched to Firebase.

---

## 2. Enabling Firebase Analytics Debug Mode

By default, Firebase Analytics batches events on the device for up to one hour to conserve battery. In development, enable debug mode using ADB so events stream to Firebase Console's **DebugView** within seconds.

### Step 1: Enable Debug Mode via ADB
Connect your Android phone (or launch your emulator) and execute:

```bash
adb shell setprop debug.firebase.analytics.app com.ezyhelpers.helper_partner
```
*(On Windows PowerShell, use the full ADB path if ADB is not in your system PATH:)*
```powershell
C:\Users\<YOUR_USER>\AppData\Local\Android\Sdk\platform-tools\adb.exe shell setprop debug.firebase.analytics.app com.ezyhelpers.helper_partner
```

### Step 2: Run the App
Launch the Flutter app:
```bash
cd mobile
flutter run
```

### Step 3: Trigger the 3 Events
Perform the end-to-end user flow:
1. **Login Event**: Sign in on the Login Screen using `helper1` / `Demo@1234`.
   - Console will output:
     ```text
     📊 [Analytics] Event: login_success | Parameters: {method: password}
     ```
2. **Job Viewed Event**: From the Jobs List, tap on any job card to open the Job Details screen.
   - Console will output:
     ```text
     📊 [Analytics] Event: job_viewed | Parameters: {job_id: 1, status: ASSIGNED}
     ```
3. **Status Updated Event**: Tap the primary action button (e.g. **"Start job"**), confirm the action in the dialog, and wait for the API to return 200 OK.
   - Console will output:
     ```text
     📊 [Analytics] Event: job_status_updated | Parameters: {job_id: 1, from_status: ASSIGNED, to_status: IN_PROGRESS}
     ```

---

## 3. Verifying in Firebase Console

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your development Firebase project.
3. In the left navigation sidebar, navigate to **Analytics** > **DebugView**.
4. In the **Debug Device** selector at the top, select your connected device (e.g. `V2416` or `Android SDK built for x86_64`).
5. Observe the live chronological event stream on the timeline:
   - `login_success`
   - `job_viewed`
   - `job_status_updated`
6. Click into each event to inspect parameter keys and values.

---

## 4. Disabling Debug Mode

When you are done testing, turn off DebugView mode on the device:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

---

## 5. Verification Screenshots & Evidence

*(Add your screenshots here for assessment submission)*

### 5.1 DebugView Timeline Overview
```
[ PLACEHOLDER: Insert screenshot of Firebase Console DebugView stream showing login_success, job_viewed, and job_status_updated ]
```

### 5.2 `login_success` Event Details
```
[ PLACEHOLDER: Insert screenshot showing parameters {method: "password"} ]
```

### 5.3 `job_viewed` Event Details
```
[ PLACEHOLDER: Insert screenshot showing parameters {job_id: 1, status: "ASSIGNED"} ]
```

### 5.4 `job_status_updated` Event Details
```
[ PLACEHOLDER: Insert screenshot showing parameters {job_id: 1, from_status: "ASSIGNED", to_status: "IN_PROGRESS"} ]
```
