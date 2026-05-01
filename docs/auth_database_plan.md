# employeeee Auth + Database Plan

This app should keep the current local-first workflow, then add cloud sync behind a Cloudflare Worker API.

## Recommended Stack

- Frontend: Flutter web app
- API: Cloudflare Worker
- Database: Cloudflare D1
- Auth: email/password sessions first, Google OAuth next
- Token style: short-lived JWT access token + server-stored refresh/session row

## Why This Shape

- Flutter must not contain D1 credentials or Cloudflare API tokens.
- Worker owns all database reads/writes.
- Existing local work entries can be uploaded after first login.
- The app can still work without login as a local-only wage notebook.

## D1 Tables

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  google_sub TEXT UNIQUE,
  display_name TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE pay_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,
  employment_type TEXT NOT NULL DEFAULT 'partTime',
  payload_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE work_entries (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  payload_json TEXT NOT NULL,
  work_date TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## API Draft

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google/start`
- `GET /api/auth/google/callback`
- `POST /api/auth/logout`
- `GET /api/me`
- `GET /api/pay-rule`
- `PUT /api/pay-rule`
- `GET /api/work-entries?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `PUT /api/work-entries/:id`
- `DELETE /api/work-entries/:id`
- `POST /api/sync/bootstrap`

## Sync Direction

1. User starts in local-only mode.
2. User logs in.
3. App uploads local `pay_rule` and `work_entries` to `/api/sync/bootstrap`.
4. Server stores data under `user_id`.
5. Future saves write locally first, then sync to Worker.
6. If offline, pending changes stay local and retry later.

## Payslip Integration Later

Payslip import should not overwrite work logs automatically at first. Safer flow:

1. Parse payslip rows into a temporary `payslip_imports` table.
2. Compare rows against existing `work_entries`.
3. Show differences to the user.
4. Let user approve corrections.
5. Save approved changes to `work_entries`.

## Current Implementation Status

- Login UI exists.
- Local-only auth session exists.
- Google/email password buttons are UI-ready but not connected to a Worker yet.
- `PayRule.employmentType` is stored locally and ready to sync as part of `payload_json`.
