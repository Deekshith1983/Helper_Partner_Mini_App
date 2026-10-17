# DESIGN.md — EzyHelpers Helper Partner Mini App

Use this file as the single source of truth for screen designs (feed it to Stitch / Figma AI / v0 / any design tool) and for the Flutter UI build.

---

## 1. Product summary

**App name:** EzyHelpers Partner (working title)
**Platform:** Flutter, Android only (Material 3)
**Who uses it:** A helper (service partner) who signs in, sees jobs assigned to them, opens a job, and moves it forward: `ASSIGNED -> IN_PROGRESS -> COMPLETED`.
**Tone:** Simple, trustworthy, work-focused. A helper may use it one-handed, outdoors, on a mid-range phone. Large tap targets, clear status, minimal text.
**Data:** Demo/mock data only. No real names, phone numbers or addresses.

---

## 2. User flow

```
Launch -> (token saved?) -- yes --> Jobs List
                          -- no  --> Login -> Jobs List -> Job Details -> (status update) -> back to Jobs List (refreshed)
Jobs List -> Logout -> Login
Any 401 from API -> clear token -> Login
```

Only 3 screens. No bottom navigation, no drawer.

---

## 3. Design principles

1. **Status first.** The job status is the most important thing on every job UI. Always shown as a colored chip.
2. **One primary action per screen.** Login = Sign in. Details = next status button.
3. **Every screen has all four states:** loading, empty, error, success.
4. **Thumb-friendly.** Primary buttons full-width, min height 52dp, placed at the bottom on Details.
5. **Never fail silently.** Every API error becomes visible text with a retry or a fix hint.

---

## 4. Design tokens

### Colors (light theme)

| Token | Hex | Use |
|---|---|---|
| primary | `#3B5BDB` | Buttons, app bar accents, links |
| onPrimary | `#FFFFFF` | Text on primary |
| background | `#F6F7FB` | Screen background |
| surface | `#FFFFFF` | Cards, text fields, dialogs |
| outline | `#D9DCE6` | Card borders, dividers |
| textPrimary | `#1B1F2A` | Titles, body |
| textSecondary | `#5B6275` | Captions, helper text |
| error | `#D92D20` | Error text, error banner border |
| errorBg | `#FEF3F2` | Error banner background |
| success | `#12B76A` | Success snackbar, completed |

### Status colors (chip background / text)

| Status | Label | Chip bg | Chip text |
|---|---|---|---|
| `ASSIGNED` | Assigned | `#E0E7FF` | `#3730A3` |
| `IN_PROGRESS` | In progress | `#FEF0C7` | `#93370D` |
| `COMPLETED` | Completed | `#D1FADF` | `#05603A` |

Never rely on color alone: always show the text label too.

### Typography (Material 3 scale; Inter or Roboto)

| Role | Size / weight |
|---|---|
| Screen title (AppBar) | 20 / 600 |
| Card title | 16 / 600 |
| Body | 14 / 400 |
| Caption / meta | 12 / 400 |
| Button | 16 / 600 |
| Status chip | 12 / 600 |

### Spacing, shape, elevation

- Spacing scale: 4, 8, 12, 16, 24, 32. Screen horizontal padding: 16.
- Card radius 16, button radius 12, text field radius 12, chip radius 999 (pill).
- Cards: elevation 0 with 1px `outline` border (flat, modern). Dialogs and snackbars use default Material elevation.

---

## 5. Components

| Component | Spec |
|---|---|
| **Primary button** | Filled, full width, height 52, shows a small circular spinner and is disabled while loading |
| **Text field** | Outlined, label above/floating, inline validation message, password field has show/hide toggle |
| **Status chip** | Pill, colors from the status table, text label always shown |
| **Job card** | Surface card, 16 padding: title (1 line, ellipsis), description (max 2 lines), a meta row (scheduled time + location), status chip top-right, chevron right |
| **Info row** | Left: label (caption, secondary). Right/below: value (body) |
| **Status stepper** | 3 steps in a row (Assigned, In progress, Completed). Done steps filled with a check, current step highlighted, future steps outlined |
| **Error banner** | Rounded box, `errorBg` fill, error icon, message text, optional "Retry" text button |
| **Empty state** | Centered illustration/icon, title, one-line hint, "Refresh" button |
| **Snackbar** | Floating, short text. Success (green accent) or error (red accent) |
| **Confirm dialog** | Title, one-line message, Cancel + Confirm buttons. Used before status change |

---

## 6. Screens

### 6.1 Login screen

**Purpose:** Authenticate the helper.

**Sections, top to bottom:**
1. **Brand header** — app icon/logo mark, app name "EzyHelpers Partner", tagline "Manage your jobs on the go"
2. **Form card** — title "Sign in", username field, password field (show/hide), error banner area (hidden unless an error), **Sign in** button
3. **Demo credentials hint** — small info card: "Demo build: use `helper1` / `Demo@1234`" (clearly labeled demo; helps reviewers)
4. **Footer** — "Demo build v1.0"

**Behavior:**
- Client validation: both fields required, shows inline messages
- Submit -> button shows spinner, fields disabled
- Wrong credentials -> error banner "Incorrect username or password"
- Network/server down -> error banner "Can't reach the server. Check your connection and try again."
- Success -> save token, go to Jobs List (replace route so Back does not return to Login)
- Keyboard: Enter on password submits

**Analytics:** `login_success`

---

### 6.2 Assigned jobs list screen

**Purpose:** Show only the signed-in helper's jobs.

**Sections:**
1. **App bar** — title "My Jobs", **Refresh** icon button, **Logout** icon/menu
2. **Greeting / summary strip** — "Hi, {name}" + small counts, e.g. "3 assigned · 1 in progress · 2 completed" (optional but cheap to compute client-side)
3. **Job list** — scrollable list of job cards, newest first or by scheduled time; **pull-to-refresh**
4. **State areas** (replace the list when active):
   - **Loading:** centered spinner (or skeleton cards)
   - **Empty:** "No jobs assigned yet" + hint "New jobs will show up here" + Refresh button
   - **Error:** error banner with message + **Retry**

**Behavior:**
- Tap a card -> Job Details
- Returning from Details reloads the list so statuses stay fresh
- 401 -> clear token, go to Login with a snackbar "Session expired"

**Analytics:** none required here (`job_viewed` fires on opening details)

---

### 6.3 Job details screen

**Purpose:** View one job and move it to the next permitted status.

**Sections:**
1. **App bar** — back arrow, title "Job #{id}"
2. **Header block** — job title (large) + status chip
3. **Status stepper** — Assigned -> In progress -> Completed, current step highlighted
4. **Details card** — info rows: Description, Customer (fake name), Location (fake area), Scheduled time, Created at, Job ID
5. **Action area (sticky bottom)** — one primary button depending on status:
   - `ASSIGNED` -> **"Start job"** (moves to IN_PROGRESS)
   - `IN_PROGRESS` -> **"Mark as completed"** (moves to COMPLETED)
   - `COMPLETED` -> no action; show a disabled-style "Completed" label with a check

**States:**
- **Loading** (fetching details): spinner
- **Error** (fetch failed / not found): error banner + Retry; 404 shows "Job not found"
- **Updating:** button shows spinner, is disabled
- **Update success:** snackbar "Job moved to In progress", stepper and chip update immediately
- **Update error:** snackbar/banner with the server's message (e.g. "Invalid status transition"), UI stays on the old status

**Behavior:**
- Optional confirm dialog before status change ("Start this job?")
- On open: call `GET /api/jobs/{id}/` (fresh data), then log `job_viewed`
- Return to list with a result flag so the list refreshes

**Analytics:** `job_viewed` (on open), `job_status_updated` (on success)

---

## 7. Status model (UI rules)

```
ASSIGNED --(Start job)--> IN_PROGRESS --(Mark as completed)--> COMPLETED
```

- No skipping (ASSIGNED -> COMPLETED is invalid)
- No going backward
- No action once COMPLETED
- The UI only offers the one valid next step; the **backend still validates** and is the real authority.

---

## 8. Microcopy

| Situation | Text |
|---|---|
| Login title | Sign in |
| Wrong credentials | Incorrect username or password |
| Offline / server down | Can't reach the server. Check your connection and try again. |
| Empty list | No jobs assigned yet |
| List load failed | Couldn't load your jobs. Tap Retry. |
| Not found | Job not found |
| Invalid transition | This job can't move to that status. Refresh and try again. |
| Success | Job moved to {status label} |
| Session expired | Session expired. Please sign in again. |

---

## 9. Accessibility

- Minimum tap target 48x48dp
- Text contrast at least 4.5:1 (token pairs above meet this)
- Status shown by text + color
- Semantic labels on icon buttons (Refresh, Logout, Back)
- Support system font scaling (no fixed-height text containers)

---

## 10. Assessment requirements (what must exist)

### Mandatory scope

**Backend (Django REST Framework, SQLite or PostgreSQL)**
- [ ] Helper login with token authentication, demo credentials
- [ ] `GET /api/jobs/` returns only the signed-in helper's jobs
- [ ] `GET /api/jobs/{id}/` job details, ownership enforced
- [ ] `PATCH /api/jobs/{id}/status/` with validated transitions
- [ ] Jobs stored persistently in the database
- [ ] Proper HTTP errors: 400 invalid transition/value, 401 unauthenticated, 403/404 not your job, 404 missing
- [ ] At least 2 tests: permission (cannot touch another helper's job) and status validation (invalid transition rejected)
- [ ] Demo data seeded (fake only)

**Flutter (Android)**
- [ ] Login screen
- [ ] Assigned-jobs list screen
- [ ] Job-details screen
- [ ] Calls the real backend (no hardcoded data)
- [ ] Permitted status changes only
- [ ] Loading, empty and error states
- [ ] Refresh action

**Firebase**
- [ ] Firebase Analytics in a dev Firebase project
- [ ] Events: `login_success`, `job_viewed`, `job_status_updated`
- [ ] DebugView verification documented (screenshots or short demo)

**Git / GitHub**
- [ ] GitHub repository
- [ ] Meaningful commits
- [ ] A feature branch
- [ ] A pull request into `main`
- [ ] README: setup instructions + architecture overview (+ API examples + known limitations)

**Build and delivery**
- [ ] Working debug APK
- [ ] Demo login credentials
- [ ] Short screen recording of the end-to-end flow (3-5 min walkthrough)
- [ ] Brief summary of completed vs deferred work

### Submission checklist

- [ ] GitHub repository URL
- [ ] Pull request URL
- [ ] APK file or accessible download link + test credentials
- [ ] README
- [ ] Firebase DebugView evidence
- [ ] 3-5 minute walkthrough video
- [ ] Completed vs deferred summary

### Optional stretch (only after everything above works)

FCM push notification, Crashlytics, pagination/filtering, offline caching, CI workflow, Docker Compose, UI polish.

### Rules

- Mock/demo data only; do not use EzyHelpers production systems or real personal data.
- Do not commit secrets, service-account keys or real user information.
- You may use AI and libraries, but you must understand and explain all submitted code.
- Submit what works by the deadline; state limitations and next steps clearly.

### Grading rubric (100 points)

| Category | Points |
|---|---|
| End-to-end working flow | 30 |
| Backend and API safety | 20 |
| Flutter quality | 20 |
| GitHub and delivery | 15 |
| Firebase + testing | 10 |
| Ownership and communication | 5 |

---

## 11. Prompt to paste into a design tool

> Design a 3-screen Android mobile app (Material 3, light theme) called "EzyHelpers Partner" for service helpers to manage assigned jobs. Screens: (1) Login with brand header, username and password fields (show/hide), error banner, "Sign in" button and a small demo-credentials hint card; (2) "My Jobs" list with app bar (title, refresh icon, logout), a one-line summary of job counts, and job cards showing title, 2-line description, scheduled time, location and a colored status chip (Assigned = indigo, In progress = amber, Completed = green), plus empty and error states; (3) Job Details with title + status chip, a 3-step status stepper, a details card (description, customer, location, scheduled time, created at, job ID) and a sticky bottom full-width button that says "Start job" or "Mark as completed" depending on status. Primary color #3B5BDB, background #F6F7FB, white cards with 16px radius and 1px #D9DCE6 border, 16px page padding, Inter font. Clean, flat, high-contrast, thumb-friendly. Also generate the loading, empty and error variants of the list screen.
