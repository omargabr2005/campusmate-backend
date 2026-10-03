# CampusMate Backend

Backend API for the CampusMate graduation project.

## Technologies

- Python
- FastAPI
- SQLAlchemy
- MySQL
- Uvicorn

## Current APIs

### Get Groups

GET /groups

Returns all active student groups.

### Get Group Schedule

GET /groups/{group_id}/schedule

Returns the schedule for a specific student group.

### Get Staff

GET /staff

Returns active doctors and teaching assistants with their office locations.

## Database

The backend uses MySQL database:

campusmate

## Setup

1. Create a Python virtual environment.

2. Install dependencies:

```bash
pip install -r requirements.txt