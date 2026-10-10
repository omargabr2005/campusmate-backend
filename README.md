# CampusMate Backend

Backend API for the CampusMate graduation project: a campus assistant that
handles staff presence (face recognition), schedules, events, competitions,
and academic advising.

## Technologies

- Python 3.11
- FastAPI
- SQLAlchemy
- PostgreSQL (hosted on Aiven)
- psycopg2
- Uvicorn

## Project structure

```
.
├── main.py                  # FastAPI app entry point
├── face_routes.py           # Face-recognition and presence endpoints
├── database.py              # SQLAlchemy engine and session (PostgreSQL)
├── project.sql              # Base schema (run first)
├── sql/
│   ├── advisor_gpa_migration.sql        # Advisors + secured GPA table
│   └── rooms_competitions_migration.sql # Buildings, floors, rooms, competitions
├── requirements.txt
├── .env.example             # Template for local environment variables
└── README.md
```

## Getting started

### 1. Clone and create a virtual environment

```bash
git clone https://github.com/omargabr2005/campusmate-backend.git
cd campusmate-backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure environment variables

Copy the template and fill in the real values (ask the project owner for them):

```bash
cp .env.example .env
```

```
DB_HOST=your-host.aivencloud.com
DB_PORT=5432
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=defaultdb
FACE_API_KEY=change-me
```

`FACE_API_KEY` is a long random string shared **only** with the face-recognition
device. Generate one with:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

> **Never commit `.env`.** It is listed in `.gitignore`. Credentials are shared
> privately, not through the repository.

### 3. Set up the database (only for a new, empty database)

The shared Aiven database is already set up. If you create a new one, run the
SQL files **in this order**:

1. `project.sql`
2. `sql/advisor_gpa_migration.sql`
3. `sql/rooms_competitions_migration.sql`

Using `psql` (the Aiven SQL editor limits each run to 10 statements, so it is
not suitable for these files):

```bash
psql "<SERVICE_URI_FROM_AIVEN>" -f project.sql
psql "<SERVICE_URI_FROM_AIVEN>" -f sql/advisor_gpa_migration.sql
psql "<SERVICE_URI_FROM_AIVEN>" -f sql/rooms_competitions_migration.sql
```

Run each file only once; running a file twice fails with "already exists".

### 4. Run the server

```bash
uvicorn main:app --reload
```

- API: http://127.0.0.1:8000
- Interactive docs: http://127.0.0.1:8000/docs

## Current APIs

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| GET | `/` | Health check | None |
| GET | `/staff/status` | Who is in the office right now | None |
| GET | `/face/embeddings` | Download all active face embeddings (device startup) | `x-api-key` header |
| POST | `/face/embeddings` | Enroll one embedding sample for a staff member | `x-api-key` header |
| POST | `/face/presence` | Log that a recognized staff member came In / went Out | `x-api-key` header |

Embedding format on the wire: base64 of 128 x float32 little-endian (512 bytes).
In PostgreSQL it is stored as raw bytes (`BYTEA`) in `face_recognition.face_embedding`.

## Database overview

Main tables:

- **Academic:** `Departments`, `AcademicPrograms`, `student_Groups`, `Students`,
  `Courses`, `Course_Programs`, `Schedule`, `Enrollments`
- **Staff:** `staff` (doctors and teaching assistants, distinguished by `role`),
  `office_hours`, `presence_log`, `face_recognition`
- **Advising:** `advisors`, `student_gpa` (GPA is kept in its own table on
  purpose and must only be exposed to the student's own advisor)
- **Campus:** `buildings`, `floors`, `rooms`, `events`, `Event_Attendance`,
  `competitions`, `competition_registrations`
- **Auth and audit:** `Roles`, `Users`, `access_logs`
- **Views:** `staff_current_status`, `office_hours_view`, `advisor_students`

The data-science table `students_cleaned` (cleaned student data for the NLP
team) lives in the same database but is separate from the application tables.

## Security notes

- Credentials live only in `.env` (never committed).
- Face-recognition write/read endpoints require the `x-api-key` header.
- Student GPA must never be returned by public or robot endpoints. It is only
  available to an authenticated advisor, filtered to their own students.
- The Aiven service has a connection limit of 15, so the pool size is kept
  small (`pool_size=3`). Do not keep long-lived idle connections open.
- NLP team members use a separate **read-only** database user with access to
  `students_cleaned` only.
