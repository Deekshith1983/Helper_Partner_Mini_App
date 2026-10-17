# API Documentation: Helper Partner Mini App

Base URL:
- Local Machine: `http://127.0.0.1:8000/api`
- Android Emulator: `http://10.0.2.2:8000/api`

---

## 1. Authentication

The API uses Django REST Framework Token Authentication.
Pass the auth token in the request header:
```http
Authorization: Token <YOUR_AUTH_TOKEN>
```

### Error Response Format
All errors across the API follow a uniform JSON schema:
```json
{
  "detail": "Descriptive error message"
}
```

---

## 2. Endpoints

### 2.1 Login
**`POST /api/auth/login/`**

Authenticates a helper with username and password, returning an auth token and user profile summary.

#### Success Request (200 OK)
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "helper1", "password": "Demo@1234"}'
```
**Response Body (200 OK):**
```json
{
  "token": "283fff1379672634319ba0d3e72a99e27fece1ae",
  "user": {
    "id": 1,
    "username": "helper1",
    "name": "Ramesh Kumar"
  }
}
```

#### Error: Invalid Credentials (401 Unauthorized)
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "helper1", "password": "WrongPassword"}'
```
**Response Body (401 Unauthorized):**
```json
{
  "detail": "Invalid username or password."
}
```

#### Error: Missing Fields (400 Bad Request)
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "helper1"}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "password: This field is required."
}
```

---

### 2.2 List Jobs
**`GET /api/jobs/`**

Returns only the jobs assigned to the authenticated helper, sorted chronologically by `scheduled_at`.

#### Success Request (200 OK)
```bash
curl http://127.0.0.1:8000/api/jobs/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae"
```
**Response Body (200 OK):**
```json
[
  {
    "id": 5,
    "title": "Balcony Wash & Pigeon Net Sanitization",
    "description": "High-pressure wash for two balconies and bird droppings disinfection.",
    "customer_name": "Sunita Menon",
    "location": "Flat 204, Salarpuria Greenage, Bommanahalli, Bengaluru",
    "scheduled_at": "2026-10-16T11:27:48.515022Z",
    "status": "COMPLETED",
    "helper": 1,
    "created_at": "2026-10-17T11:27:43.229471Z"
  },
  {
    "id": 4,
    "title": "Bathroom Floor Tile Scrubbing & Descaling",
    "description": "Acid-free chemical descaling for master and guest bathrooms. Tap and sanitary fittings buffing.",
    "customer_name": "Karthik Rao",
    "location": "House 88, 12th Main, Indiranagar, Bengaluru",
    "scheduled_at": "2026-10-17T08:27:48.515022Z",
    "status": "IN_PROGRESS",
    "helper": 1,
    "created_at": "2026-10-17T11:27:43.227458Z"
  },
  {
    "id": 1,
    "title": "Deep Cleaning - 2 BHK Apartment",
    "description": "Full deep cleaning of 2 bedrooms, hall, kitchen, and 2 bathrooms. Equipment provided on site.",
    "customer_name": "Pooja Sharma",
    "location": "Flat 402, Green Glen Layout, Bellandur, Bengaluru",
    "scheduled_at": "2026-10-17T13:27:48.515022Z",
    "status": "ASSIGNED",
    "helper": 1,
    "created_at": "2026-10-17T11:27:43.196158Z"
  }
]
```

#### Error: Unauthenticated (401 Unauthorized)
```bash
curl http://127.0.0.1:8000/api/jobs/
```
**Response Body (401 Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### 2.3 Job Detail
**`GET /api/jobs/{id}/`**

Retrieves full details of a specific job assigned to the authenticated helper.

#### Success Request (200 OK)
```bash
curl http://127.0.0.1:8000/api/jobs/1/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae"
```
**Response Body (200 OK):**
```json
{
  "id": 1,
  "title": "Deep Cleaning - 2 BHK Apartment",
  "description": "Full deep cleaning of 2 bedrooms, hall, kitchen, and 2 bathrooms. Equipment provided on site.",
  "customer_name": "Pooja Sharma",
  "location": "Flat 402, Green Glen Layout, Bellandur, Bengaluru",
  "scheduled_at": "2026-10-17T13:27:48.515022Z",
  "status": "ASSIGNED",
  "helper": 1,
  "created_at": "2026-10-17T11:27:43.196158Z"
}
```

#### Error: Job Not Found or Belongs to Another Helper (404 Not Found)
*Note: Returning 404 for jobs owned by other helpers prevents ID enumeration and privacy leaks.*
```bash
curl http://127.0.0.1:8000/api/jobs/6/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae"
```
**Response Body (404 Not Found):**
```json
{
  "detail": "Job not found."
}
```

#### Error: Unauthenticated (401 Unauthorized)
```bash
curl http://127.0.0.1:8000/api/jobs/1/
```
**Response Body (401 Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### 2.4 Update Job Status
**`PATCH /api/jobs/{id}/status/`**

Updates the lifecycle status of a job.
Only the `status` field is modified. Any additional fields in the payload are ignored.

#### State Machine Transition Rules
| Current Status | Allowed Target Status | Notes |
| :--- | :--- | :--- |
| `ASSIGNED` | `IN_PROGRESS` | Helper begins job execution |
| `IN_PROGRESS` | `COMPLETED` | Helper finishes the service |
| `COMPLETED` | *None* | Final state; no further transitions allowed |

#### Success Request: ASSIGNED -> IN_PROGRESS (200 OK)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "IN_PROGRESS"}'
```
**Response Body (200 OK):**
```json
{
  "id": 1,
  "title": "Deep Cleaning - 2 BHK Apartment",
  "description": "Full deep cleaning of 2 bedrooms, hall, kitchen, and 2 bathrooms. Equipment provided on site.",
  "customer_name": "Pooja Sharma",
  "location": "Flat 402, Green Glen Layout, Bellandur, Bengaluru",
  "scheduled_at": "2026-10-17T13:27:48.515022Z",
  "status": "IN_PROGRESS",
  "helper": 1,
  "created_at": "2026-10-17T11:27:43.196158Z"
}
```

#### Success Request: IN_PROGRESS -> COMPLETED (200 OK)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "COMPLETED"}'
```
**Response Body (200 OK):**
```json
{
  "id": 1,
  "title": "Deep Cleaning - 2 BHK Apartment",
  "description": "Full deep cleaning of 2 bedrooms, hall, kitchen, and 2 bathrooms. Equipment provided on site.",
  "customer_name": "Pooja Sharma",
  "location": "Flat 402, Green Glen Layout, Bellandur, Bengaluru",
  "scheduled_at": "2026-10-17T13:27:48.515022Z",
  "status": "COMPLETED",
  "helper": 1,
  "created_at": "2026-10-17T11:27:43.196158Z"
}
```

#### Error: Skipping Status (ASSIGNED -> COMPLETED) (400 Bad Request)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "COMPLETED"}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "Invalid status transition from 'ASSIGNED' to 'COMPLETED'. Allowed transitions from 'ASSIGNED': [IN_PROGRESS]."
}
```

#### Error: Backward Move (IN_PROGRESS -> ASSIGNED) (400 Bad Request)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/3/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "ASSIGNED"}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "Invalid status transition from 'IN_PROGRESS' to 'ASSIGNED'. Allowed transitions from 'IN_PROGRESS': [COMPLETED]."
}
```

#### Error: Transition to Same Status (ASSIGNED -> ASSIGNED) (400 Bad Request)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "ASSIGNED"}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "Job is already in status 'ASSIGNED'. Status transition is not allowed."
}
```

#### Error: Invalid Status Value (e.g. "FOO") (400 Bad Request)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "FOO"}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "Invalid status 'FOO'. Valid statuses are: ASSIGNED, IN_PROGRESS, COMPLETED."
}
```

#### Error: Missing Status Field (400 Bad Request)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Response Body (400 Bad Request):**
```json
{
  "detail": "Field 'status' is required."
}
```

#### Error: Target Job Belongs to Another Helper (404 Not Found)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/6/status/ \
  -H "Authorization: Token 283fff1379672634319ba0d3e72a99e27fece1ae" \
  -H "Content-Type: application/json" \
  -d '{"status": "IN_PROGRESS"}'
```
**Response Body (404 Not Found):**
```json
{
  "detail": "Job not found."
}
```

#### Error: Unauthenticated (401 Unauthorized)
```bash
curl -X PATCH http://127.0.0.1:8000/api/jobs/1/status/ \
  -H "Content-Type: application/json" \
  -d '{"status": "IN_PROGRESS"}'
```
**Response Body (401 Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```
