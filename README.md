# Helper Partner Mini App

A lightweight, robust mobile application and backend service built for **EzyHelpers** service partners to manage assigned jobs on the go.

---

## 1. Project Overview & User Flow

The application provides a distraction-free, one-handed mobile experience for service helpers:
1. **Sign In**: Helper authenticates using their credentials.
2. **Jobs Overview**: Helper views strictly their assigned service jobs, accompanied by an interactive status summary strip.
3. **Job Details & Execution**: Helper opens an assigned job, inspects location/instructions, and advances it through a strict lifecycle:
   ```
   ASSIGNED ──(Start job)──> IN_PROGRESS ──(Mark as completed)──> COMPLETED
   ```
4. **Data Isolation & Security**: Helpers cannot view or mutate any jobs belonging to other partners.
5. **Analytics**: Three non-PII operational events stream to Firebase Analytics (`login_success`, `job_viewed`, and `job_status_updated`).

```
[ App Launch ] ──> Token cached? ──Yes──> [ Jobs List ] ──> [ Job Details ] ──> [ Status Transition ]
                          │                       │
                          No                      └─ Logout ──> [ Login Screen ]
                          ▼
                   [ Login Screen ]
```

---

## 2. Architecture & Design Decisions

### System Architecture
```text
┌──────────────────────────────────────────────┐
│            Flutter Android Client            │
│  (Material 3, Provider State, HTTP Client)   │
└──────────────────────┬───────────────────────┘
                       │
       REST API (HTTP) │   Authorization: Token <token>
                       ▼
┌──────────────────────────────────────────────┐       ┌────────────────────────┐
│            Django REST Framework             │       │   Firebase Analytics   │
│  - TokenAuthentication                       ├──────>│   (Dev DebugView)      │
│  - Strict State Machine Dict                 │       │   (3 non-PII events)   │
│  - Atomic Concurrency (select_for_update)    │       └────────────────────────┘
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│               SQLite Database                │
│    (Users, Tokens, Jobs, Status Choices)     │
└──────────────────────────────────────────────┘
```

### Monorepo Structure
```text
.
├── backend/                       # Python / Django REST API
│   ├── config/                    # Django project settings & root URLs
│   ├── jobs/                      # Jobs app: models, views, serializers, admin
│   │   └── management/commands/   # seed_demo command for idempotent mock data
│   ├── pytest.ini                 # Pytest runner configuration
│   └── requirements.txt           # Python backend dependencies
├── mobile/                        # Flutter Android Application
│   ├── android/                   # Native Android host & debug cleartext config
│   ├── lib/
│   │   ├── core/                  # Theme tokens (DESIGN.md), constants, API client
│   │   ├── models/                # Job, User, JobStatus domain models
│   │   ├── providers/             # AuthProvider, JobsProvider
│   │   ├── screens/               # Login, Jobs List, Job Details screens
│   │   ├── services/              # AuthService, JobService, TokenStorage, Analytics
│   │   └── widgets/               # StatusChip, JobCard, StatusStepper, ErrorBanner
│   └── pubspec.yaml               # Flutter package configuration
├── docs/                          # Comprehensive Technical Documentation
│   ├── API.md                     # Endpoint specifications & curl examples
│   ├── FIREBASE_DEBUGVIEW.md      # Firebase verification & ADB debug guide
│   ├── END_TO_END_TESTING.md      # Full E2E test matrix & verification runbook
├── .gitignore                     # Multi-layer secret & build artifact protection
└── README.md                      # Primary project documentation
```

### Key Architectural Decisions
- **TokenAuthentication**: DRF's standard token authentication provides rock-solid security without the bloat and complexity of JWT refresh token rotations.
- **Provider State Management**: Clean separation of UI, business logic, and API calls via `ChangeNotifier`.
- **404 Ownership Security Rule**: Accessing another helper's job ID returns `404 Not Found` (instead of `403 Forbidden`) to prevent resource enumeration and helper activity snooping.
- **Single Dictionary State Machine**: Transitions are enforced centrally in Python (`ALLOWED_TRANSITIONS`) wrapped with `transaction.atomic()` and `select_for_update()` to prevent race conditions.

---

## 3. Demo Credentials

Seed data provisions two test helpers with 5 mock jobs each:

| Helper Account | Username | Password | Assigned Jobs |
| :--- | :--- | :--- | :--- |
| **Helper 1 (Ramesh)** | `helper1` | `Demo@1234` | 5 jobs (2 Assigned, 2 In Progress, 1 Completed) |
| **Helper 2 (Suresh)** | `helper2` | `Demo@1234` | 5 jobs (2 Assigned, 1 In Progress, 2 Completed) |

---

## 4. Backend Setup & Run Guide

### Prerequisites
- Python 3.11 or higher
- Git

### 1. Initialize Virtual Environment & Install Dependencies
```powershell
cd backend
python -m venv venv

# Windows PowerShell:
.\venv\Scripts\Activate.ps1

# Windows CMD:
.\venv\Scripts\activate.bat

# macOS / Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Apply Migrations & Seed Demo Data
```powershell
python manage.py migrate
python manage.py seed_demo
```
*(The `seed_demo` command is completely idempotent and safe to run multiple times).*

### 3. Run Automated Tests (17 Test Cases)
```powershell
pytest
```
*Expected result: `17 passed in ~1.5s`.*

### 4. Start Development Server
```powershell
python manage.py runserver 0.0.0.0:8000
```

---

## 5. Mobile (Flutter) Setup & Run Guide

### Prerequisites
- Flutter SDK 3.19+ (installed at `C:\src\flutter\bin`)
- Android SDK & Android Device (physical device or emulator)

### 1. Install Dependencies
```powershell
cd mobile
flutter pub get
```

### 2. Run Static Analysis & Tests
```powershell
flutter analyze
flutter test
```
*Expected result: `No issues found!` and `All tests passed!`.*

### 3. Firebase Configuration (Optional for Local Runs)
The app runs out-of-the-box without crashing if Firebase credentials are omitted. To connect your own Firebase project:
1. Download `google-services.json` from your Firebase Console.
2. Place it at `mobile/android/app/google-services.json` *(an example template is provided at [`mobile/android/app/google-services.json.example`](mobile/android/app/google-services.json.example))*.

### 4. Running the App

#### Running on Android Emulator
The Android emulator automatically maps `10.0.2.2` to your PC's localhost:
```powershell
flutter run
```

#### Running on a Physical Android Phone via USB
Forward the backend port over the USB cable:
```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

#### Running on a Physical Phone via Local Wi-Fi
Find your PC's IP address (e.g. `192.168.0.101` via `ipconfig`) and run:
```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.0.101:8000
```

### 5. Building the Debug APK
```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.0.101:8000
```
*Output APK located at: `mobile/build/app/outputs/flutter-apk/app-debug.apk`*

---

## 6. API Contract & Testing Samples

Complete endpoint documentation and error schemas are in [docs/API.md](docs/API.md).

### Quick Testing cURLs

#### 1. Login
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "helper1", "password": "Demo@1234"}'
```
*Returns:* `200 OK` with `token` and `user` object.

#### 2. List Jobs (Own Jobs Only)
```bash
curl http://127.0.0.1:8000/api/jobs/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae"
```
*Returns:* `200 OK` with 5 jobs assigned strictly to `helper1`.

#### 3. Update Status (Strict Transition Validation)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "IN_PROGRESS"}'
```
*Returns:* `200 OK` on valid progression (`ASSIGNED -> IN_PROGRESS`), or `400 Bad Request` on invalid skips/backward attempts.

---

## 7. Firebase Analytics & DebugView Verification

The app dispatches 3 events without transmitting personal information:
- `login_success` (`{"method": "password"}`)
- `job_viewed` (`{"job_id": <int>, "status": <string>}`)
- `job_status_updated` (`{"job_id": <int>, "from_status": <string>, "to_status": <string>}`)

Detailed step-by-step instructions for streaming events in real time via ADB and viewing them in Firebase Console are in [docs/FIREBASE_DEBUGVIEW.md](docs/FIREBASE_DEBUGVIEW.md).

---

## 8. Completed vs. Deferred Scope

| Component | Status | Notes |
| :--- | :---: | :--- |
| **Django REST Backend** | ✅ Completed | Models, views, serializers, admin, seed |
| **Ownership Enforced (404)** | ✅ Completed | Fully stops cross-helper ID enumeration |
| **Strict State Transitions** | ✅ Completed | ASSIGNED $\rightarrow$ IN_PROGRESS $\rightarrow$ COMPLETED |
| **Backend Test Suite** | ✅ Completed | 17/17 tests passing in pytest |
| **Flutter Mobile App** | ✅ Completed | 3 screens, Material 3, DESIGN.md specs |
| **All Component States** | ✅ Completed | Loading, empty, error (with retry), success |
| **Auto-login & Session Expiry** | ✅ Completed | Auto-verifies token; 401 redirects to login |
| **Firebase Analytics Integration** | ✅ Completed | 3 events with console debugPrint and zero PII |
| **Debug APK Support** | ✅ Completed | Configurable `--dart-define=API_BASE_URL` |

---

## 9. Known Limitations & Next Steps

1. **Local Backend Connectivity**: The debug APK communicates with a local/LAN backend (`10.0.2.2` or local IP). In a production release, the backend should be hosted behind HTTPS on a cloud provider (e.g. AWS ECS / DigitalOcean).
2. **Offline Mode**: If network connectivity drops while performing an action, an error banner with a Retry action is displayed. A future enhancement would be local offline queuing via Hive or SQLite.
3. **Pagination**: The API currently returns the full active job list. For scale, cursor-based pagination should be added.
4. **Cleartext HTTP**: Cleartext traffic is enabled strictly for development debug builds in `android/app/src/debug/AndroidManifest.xml` and disabled in release builds.
