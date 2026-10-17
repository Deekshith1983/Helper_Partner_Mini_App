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

## API Ownership & Security Policy
- **Ownership Rule**: Every helper can ONLY access jobs assigned to their user account (`helper=request.user`).
- **404 Behavior**: If an authenticated helper attempts to access (`GET`) or mutate (`PATCH`) a job ID that belongs to another helper (or does not exist), the API returns **`404 Not Found`** with `{"detail": "Job not found."}`.
- **Rationale**: Returning 404 rather than 403 prevents attackers or other helpers from enumerating job IDs or discovering the existence and activity of other helpers on the platform.
