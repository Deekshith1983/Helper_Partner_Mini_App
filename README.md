# Helper Partner Mini App

A simplified partner/helper application built as a hiring assessment for EzyHelpers.

## Architecture
- `backend/`: Python 3.12, Django 5.2, Django REST Framework, TokenAuthentication, SQLite.
- `mobile/`: Flutter (Android) application with Material 3 & Provider (Stage 3+).

## Monorepo Layout
```text
.
├── backend/                  # Python / Django REST API
│   ├── config/               # Project configuration & root URLs
│   ├── jobs/                 # Jobs domain, models, views, serializers, seed
│   ├── pytest.ini            # Pytest configuration
│   └── requirements.txt      # Python dependencies
├── mobile/                   # Flutter Android client
├── .gitignore
└── README.md
```

## Backend Setup & Instructions

### 1. Create and Activate Virtual Environment
```bash
cd backend
python -m venv venv

# Windows PowerShell:
.\venv\Scripts\Activate.ps1

# Windows CMD:
.\venv\Scripts\activate.bat

# macOS / Linux:
source venv/bin/activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Run Migrations & Seed Demo Data
```bash
python manage.py migrate
python manage.py seed_demo
```
The `seed_demo` command is idempotent and provisions two demo helpers:
- `helper1` / `Demo@1234` (5 mock jobs)
- `helper2` / `Demo@1234` (5 mock jobs)

### 4. Run Automated Tests
```bash
pytest
```

### 5. Start Development Server
```bash
python manage.py runserver 0.0.0.0:8000
```

---

## Mobile (Flutter Android) Setup & Instructions

### 1. Prerequisites
- Flutter SDK (installed at `C:\src\flutter\bin`, added to `PATH`)
- Android SDK & Android Emulator (or physical Android phone with USB Debugging enabled)

### 2. Install Flutter Dependencies
```bash
cd mobile
flutter pub get
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Running the App

#### A. Running on Android Emulator (Default)
The app defaults to `http://10.0.2.2:8000` which maps to your host machine's localhost inside the Android emulator:
```bash
flutter run
```

#### B. Running on a Physical Android Phone
1. Connect your PC and Android phone to the same Wi-Fi / local network.
2. Find your PC's local IP address (e.g., `192.168.1.45` via `ipconfig`).
3. Ensure the Django dev server is listening on all interfaces:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
4. Run Flutter with `--dart-define=API_BASE_URL`:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.45:8000
   ```

#### C. Build Debug APK
```bash
flutter build apk --debug
# APK output: mobile/build/app/outputs/flutter-apk/app-debug.apk
```

---

## Firebase Analytics & DebugView

The application logs three core lifecycle events (with zero PII):
1. `login_success` (`{"method": "password"}`)
2. `job_viewed` (`{"job_id": <int>, "status": <string>}`)
3. `job_status_updated` (`{"job_id": <int>, "from_status": <string>, "to_status": <string>}`)

### Configuring Your Firebase Project
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app with package name: `com.ezyhelpers.helper_partner`.
3. Download `google-services.json` and place it at:
   `mobile/android/app/google-services.json`
   *(An example template is provided at [`mobile/android/app/google-services.json.example`](mobile/android/app/google-services.json.example). Real credential files are git-ignored to prevent accidental leaks).*
4. Enable near-real-time event streaming in Firebase DebugView:
   See full instructions in [docs/FIREBASE_DEBUGVIEW.md](docs/FIREBASE_DEBUGVIEW.md).

---

## API Ownership & Security Policy
- **Ownership Rule**: Every helper can ONLY access jobs assigned to their user account (`helper=request.user`).
- **404 Behavior**: If an authenticated helper attempts to access (`GET`) or mutate (`PATCH`) a job ID that belongs to another helper (or does not exist), the API returns **`404 Not Found`** with `{"detail": "Job not found."}`.
- **Rationale**: Returning 404 rather than 403 prevents attackers or other helpers from enumerating job IDs or discovering the existence and activity of other helpers on the platform.

