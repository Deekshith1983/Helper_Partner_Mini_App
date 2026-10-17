# End-to-End (E2E) Testing Guide & Test Matrix

This document provides a comprehensive, step-by-step End-to-End (E2E) testing specification and verification runbook for the **Helper Partner Mini App**.

It validates the complete system integration across:
- **Backend**: Django REST Framework + SQLite + TokenAuthentication + Atomic State Machine
- **Mobile**: Flutter Android Application + Material 3 UI + Provider State Management + Local Storage
- **Telemetry**: Firebase Analytics + DebugView stream + zero PII compliance
- **Network & Security**: Port forwarding, Cleartext HTTP policy in debug mode, and cross-helper isolation

---

## 1. Test Environment Setup & Pre-Flight Checklist

Before executing tests, ensure the environment is initialized in a clean, reproducible state.

### Step 1: Database Reset & Idempotent Seed
In your backend terminal:
```powershell
cd backend
.\venv\Scripts\Activate.ps1

# Run migrations and reset seed data
python manage.py migrate
python manage.py seed_demo
```
*Expected Output:*
```text
Starting demo database seed...
Helper 1 ready: helper1 (Token: 283fff1379672634319ba0d3e72a99e27fece1ae)
Helper 2 ready: helper2 (Token: b1f67cbd55b6d3fb529d8a8b40d2e17ea6571b15)
Successfully seeded demo data: helper1 has 5 jobs, helper2 has 5 jobs.
```

### Step 2: Start Backend Server
```powershell
python manage.py runserver 0.0.0.0:8000
```
*Verify live at:* `http://127.0.0.1:8000/api/jobs/` (should return 401 Unauthorized without token).

### Step 3: Forward Port Over USB (Physical Android Phone)
If testing on a physical Android device:
```powershell
C:\Users\dikid\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
```

### Step 4: Enable Firebase DebugView on Device
```powershell
C:\Users\dikid\AppData\Local\Android\Sdk\platform-tools\adb.exe shell setprop debug.firebase.analytics.app com.ezyhelpers.helper_partner
```

### Step 5: Launch Mobile App
In your mobile terminal:
```powershell
cd mobile
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

---

## 2. Test Execution Matrix

### Test Suite 1: Authentication & Session Management (E2E-AUTH)

| Test ID | Test Scenario | Steps to Execute | Expected Behavior | Pass / Fail |
| :--- | :--- | :--- | :--- | :---: |
| **TC-AUTH-01** | **Client-side Form Validation** | 1. Clear both username and password.<br>2. Tap "Sign in". | Form highlights both fields in red.<br>Shows inline errors: *"Username is required"* and *"Password is required"*. No network call is made. | [ ] |
| **TC-AUTH-02** | **Invalid Credentials Handling** | 1. Enter `helper1` / `WrongPass123`.<br>2. Tap "Sign in". | API returns 401.<br>App displays red `ErrorBanner`: *"Incorrect username or password"*. User remains on Login screen. | [ ] |
| **TC-AUTH-03** | **Successful Login Flow** | 1. Enter `helper1` / `Demo@1234`.<br>2. Tap "Sign in". | 1. Button shows spinner and disables.<br>2. API returns 200 with token and user object.<br>3. Token cached in SharedPreferences.<br>4. Console outputs `login_success` analytics log.<br>5. Navigates to Jobs List (Login screen route replaced). | [ ] |
| **TC-AUTH-04** | **Auto-Login on App Restart** | 1. Close and re-open the mobile app.<br>2. Watch splash/startup phase. | `AuthProvider.tryAutoLogin()` validates cached token against API.<br>User lands directly on Jobs List without re-entering credentials. | [ ] |
| **TC-AUTH-05** | **Manual Logout Flow** | 1. On Jobs List, tap top-right Logout icon.<br>2. In confirmation dialog, tap "Cancel".<br>3. Tap Logout again $\rightarrow$ tap "Logout". | 1. Dialog cancels on first attempt.<br>2. On confirmation, token and cached user are deleted.<br>3. Route is replaced with Login Screen. | [ ] |
| **TC-AUTH-06** | **Session Expiry (401 Interception)** | 1. Log in on mobile.<br>2. Delete the token from database or terminate user session.<br>3. Tap refresh in the app. | `ApiClient` catches HTTP 401.<br>Triggers `onUnauthorized` callback.<br>Wipes local storage, routes to Login, displays *"Session expired. Please sign in again."* | [ ] |

---

### Test Suite 2: Data Isolation & Ownership Enforcement (E2E-SCOPE)

| Test ID | Test Scenario | Steps to Execute | Expected Behavior | Pass / Fail |
| :--- | :--- | :--- | :--- | :---: |
| **TC-SCOPE-01** | **Helper 1 Job Scoping** | 1. Log in as `helper1`.<br>2. Inspect list screen. | Summary strip reads *"Hi, Ramesh"* and *"2 assigned · 2 in progress · 1 completed"*.<br>Exactly 5 jobs displayed, all assigned to `helper1`. | [ ] |
| **TC-SCOPE-02** | **Helper 2 Job Scoping (Isolation)** | 1. Log out.<br>2. Log in as `helper2` / `Demo@1234`.<br>3. Inspect list screen. | Summary strip reads *"Hi, Suresh"*.<br>Displays Helper 2's specific jobs (Carpet cleaning, Curtain pressing, etc.). None of Helper 1's jobs appear. | [ ] |
| **TC-SCOPE-03** | **Cross-Helper Job Detail Access** | 1. Log in as `helper1`.<br>2. Attempt to fetch Job #6 (Helper 2's job) via curl:<br>`curl -H "Authorization: Token <H1_TOKEN>" http://127.0.0.1:8000/api/jobs/6/` | Returns **`HTTP 404 Not Found`** with `{"detail": "Job not found."}`.<br>Confirms zero data leakage between helpers. | [ ] |
| **TC-SCOPE-04** | **Cross-Helper Job Status Mutation** | 1. With Helper 1's token, attempt to PATCH Job #6:<br>`curl -X PATCH -H "Authorization: Token <H1_TOKEN>" -H "Content-Type: application/json" -d '{"status":"IN_PROGRESS"}' http://127.0.0.1:8000/api/jobs/6/status/` | Returns **`HTTP 404 Not Found`** with `{"detail": "Job not found."}`.<br>Mutation is blocked; Helper 2's job remains unchanged. | [ ] |

---

### Test Suite 3: Job Lifecycle & State Machine Validation (E2E-LIFECYCLE)

| Test ID | Test Scenario | Steps to Execute | Expected Behavior | Pass / Fail |
| :--- | :--- | :--- | :--- | :---: |
| **TC-LIFE-01** | **Open Job Details & Analytics** | 1. Log in as `helper1`.<br>2. Tap on an `ASSIGNED` job (e.g. Job #1: "Deep Cleaning - 2 BHK"). | 1. Opens Details screen.<br>2. Fetches fresh job data via API.<br>3. Console logs `📊 [Analytics] Event: job_viewed | Parameters: {job_id: 1, status: ASSIGNED}`.<br>4. Stepper highlights step 0 ("Assigned").<br>5. Sticky button reads **"Start job"**. | [ ] |
| **TC-LIFE-02** | **Transition: ASSIGNED $\rightarrow$ IN_PROGRESS** | 1. Tap **"Start job"** button.<br>2. In confirmation dialog ("Start job?"), tap "Confirm". | 1. Button shows progress spinner.<br>2. API persists `IN_PROGRESS` in database.<br>3. Console logs `📊 [Analytics] Event: job_status_updated | Parameters: {job_id: 1, from_status: ASSIGNED, to_status: IN_PROGRESS}`.<br>4. Green snackbar appears: *"Job moved to In progress"*.<br>5. Status chip and stepper update to `In progress`.<br>6. Sticky button updates to **"Mark as completed"**. | [ ] |
| **TC-LIFE-03** | **Transition: IN_PROGRESS $\rightarrow$ COMPLETED** | 1. Tap **"Mark as completed"**.<br>2. In confirmation dialog, tap "Confirm". | 1. Button shows progress spinner.<br>2. API persists `COMPLETED` in database.<br>3. Console logs `📊 [Analytics] Event: job_status_updated | Parameters: {job_id: 1, from_status: IN_PROGRESS, to_status: COMPLETED}`.<br>4. Green snackbar appears: *"Job moved to Completed"*.<br>5. Stepper shows all 3 steps completed with checks. | [ ] |
| **TC-LIFE-04** | **Terminal State Immutability** | 1. Inspect the bottom action area for Job #1 now that it is `COMPLETED`. | No action buttons exist.<br>Displays disabled-style green pill with check icon and label **"Completed"**. Further transitions are impossible in UI. | [ ] |
| **TC-LIFE-05** | **Status Persistence Across Navigation** | 1. Tap back button to return to Jobs List.<br>2. Inspect summary strip and Job #1 card. | 1. Returning from details triggers auto-refresh.<br>2. Summary strip reflects count changes.<br>3. Job #1 card displays green `Completed` chip.<br>4. Pull-to-refresh confirms data is stored persistently in SQLite. | [ ] |
| **TC-LIFE-06** | **Reject Invalid Skip Transition** | Send PATCH request via curl attempting to skip `IN_PROGRESS`: `ASSIGNED -> COMPLETED`. | Backend returns **`400 Bad Request`** with `{"detail": "Invalid status transition from 'ASSIGNED' to 'COMPLETED'. Allowed transitions from 'ASSIGNED': [IN_PROGRESS]."}`. Status in database remains `ASSIGNED`. | [ ] |
| **TC-LIFE-07** | **Reject Backward Transition** | Send PATCH request via curl attempting to revert: `IN_PROGRESS -> ASSIGNED`. | Backend returns **`400 Bad Request`** with `{"detail": "Invalid status transition from 'IN_PROGRESS' to 'ASSIGNED'. Allowed transitions from 'IN_PROGRESS': [COMPLETED]."}`. | [ ] |
| **TC-LIFE-08** | **Reject Same-Status Transition** | Send PATCH request via curl: `ASSIGNED -> ASSIGNED`. | Backend returns **`400 Bad Request`** with `{"detail": "Job is already in status 'ASSIGNED'. Status transition is not allowed."}`. | [ ] |
| **TC-LIFE-09** | **Reject Invalid Status Value** | Send PATCH request with `{"status": "FOO"}`. | Backend returns **`400 Bad Request`** with `{"detail": "Invalid status 'FOO'. Valid statuses are: ASSIGNED, IN_PROGRESS, COMPLETED."}`. | [ ] |
| **TC-LIFE-10** | **Field Isolation Integrity** | Send PATCH request with extra fields:<br>`{"status": "IN_PROGRESS", "title": "Hacked Title", "customer_name": "Hacked"}`. | Status changes to `IN_PROGRESS`, but `title` and `customer_name` remain completely untouched in the database. | [ ] |

---

### Test Suite 4: Network Resilience & Component States (E2E-UI)

| Test ID | Test Scenario | Steps to Execute | Expected Behavior | Pass / Fail |
| :--- | :--- | :--- | :--- | :---: |
| **TC-UI-01** | **Server Down / Connection Failure** | 1. Stop Django dev server (`Ctrl+C`).<br>2. Tap refresh on Jobs List. | App displays `ErrorBanner`: *"Couldn't load your jobs. Tap Retry."* with Retry action button.<br>App does not crash. | [ ] |
| **TC-UI-02** | **Error Recovery via Retry** | 1. Restart Django dev server.<br>2. Tap "Retry" on the error banner. | Error banner disappears, spinner briefly shows, and jobs list populates cleanly. | [ ] |
| **TC-UI-03** | **Empty State Verification** | 1. Create a helper with 0 jobs or delete jobs.<br>2. Log in as that helper. | Center area displays `EmptyState` widget with clipboard icon, *"No jobs assigned yet"*, *"New jobs will show up here"*, and "Refresh" button. | [ ] |
| **TC-UI-04** | **Pull-to-Refresh & AppBar Refresh** | 1. Pull down on the jobs list.<br>2. Tap the AppBar refresh icon. | Refresh indicator animates, calls API, updates jobs, and dismisses smoothly. | [ ] |

---

### Test Suite 5: Firebase Analytics Telemetry (E2E-ANALYTICS)

| Test ID | Test Scenario | Steps to Execute | Expected Behavior | Pass / Fail |
| :--- | :--- | :--- | :--- | :---: |
| **TC-LOG-01** | **Console Output Format** | Perform login, view job, update status. Observe Flutter terminal. | All 3 events print formatted messages:<br>`📊 [Analytics] Event: login_success | Parameters: {method: password}`<br>`📊 [Analytics] Event: job_viewed | Parameters: {job_id: 1, status: ASSIGNED}`<br>`📊 [Analytics] Event: job_status_updated | Parameters: {job_id: 1, from_status: ASSIGNED, to_status: IN_PROGRESS}` | [ ] |
| **TC-LOG-02** | **Firebase DebugView Event Stream** | 1. Open Firebase Console $\rightarrow$ Analytics $\rightarrow$ DebugView.<br>2. Select connected device. | Events appear in near-real-time on the 60-second and 30-minute timelines. | [ ] |
| **TC-LOG-03** | **Zero PII Validation** | Click on each event in Firebase DebugView to inspect parameter details. | **No personal data is sent**: No helper usernames, customer names, telephone numbers, or email addresses appear anywhere in parameters. | [ ] |

---

## 3. Automated Regression Verification

In addition to manual E2E validation, run the automated test suites to ensure 100% green regression coverage.

### Backend Automated Tests
```powershell
cd backend
.\venv\Scripts\pytest -v
```
*Verification Checklist:*
- [x] `test_login_success_returns_token`
- [x] `test_login_invalid_password`
- [x] `test_login_missing_fields`
- [x] `test_list_unauthenticated_rejected`
- [x] `test_list_returns_only_own_jobs`
- [x] `test_get_own_job_detail_succeeds`
- [x] `test_cannot_get_another_helper_job`
- [x] `test_get_nonexistent_job_returns_404`
- [x] `test_cannot_patch_another_helper_job`
- [x] `test_lifecycle_in_order_succeeds`
- [x] `test_skip_transition_assigned_to_completed_rejected`
- [x] `test_backward_transition_inprogress_to_assigned_rejected`
- [x] `test_backward_transition_completed_to_inprogress_rejected`
- [x] `test_same_status_transition_rejected`
- [x] `test_missing_status_field_rejected`
- [x] `test_invalid_status_value_rejected`
- [x] `test_patch_changes_only_status_ignores_other_fields`

*Result:* **17 passed in ~1.5s**

---

### Mobile Automated Tests & Static Linter
```powershell
cd mobile
flutter analyze
flutter test
```
*Verification Checklist:*
- [x] `flutter analyze`: **No issues found!** (0 errors, 0 warnings, 0 hints)
- [x] `flutter test`: **All tests passed!**

---

## 4. E2E Sign-Off Matrix

| Component | Tested By | Environment | Status |
| :--- | :--- | :--- | :---: |
| **Backend REST APIs** | Automated (`pytest`) + cURL | Windows / Python 3.12 / SQLite | **PASS** |
| **State Machine Security** | Automated (`pytest`) + cURL | Django Atomic `select_for_update` | **PASS** |
| **Mobile UI & Provider** | Manual + Device Run | Android Device (V2416 / API 36) | **PASS** |
| **Firebase Analytics** | Console DebugPrint + DebugView | Dev Firebase Project | **PASS** |
| **Zero Secrets Check** | Git Grep / File System Scan | Root Repository | **PASS** |
