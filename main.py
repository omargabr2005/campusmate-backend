from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db


app = FastAPI()


@app.get("/")
def home():
    return {
        "message": "CampusMate Backend is running"
    }


@app.get("/groups")
def get_groups(db: Session = Depends(get_db)):

    query = text("""
        SELECT
            group_id,
            group_name,
            academic_level
        FROM student_Groups
        WHERE status = 'Active'
    """)

    result = db.execute(query)

    groups = result.mappings().all()

    return groups

@app.get("/groups/{group_id}/schedule")
def get_group_schedule(
    group_id: int,
    db: Session = Depends(get_db)
):

    query = text("""
        SELECT
            sc.schedule_id,
            sc.day_of_week,
            sc.start_time,
            sc.end_time,
            c.course_code,
            c.course_name,
            sc.room,
            sc.session_type,
            sc.semester
        FROM Schedule sc
        JOIN Courses c
            ON sc.course_id = c.course_id
        WHERE sc.group_id = :group_id
        ORDER BY
            FIELD(
                sc.day_of_week,
                'Saturday',
                'Sunday',
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday'
            ),
            sc.start_time
    """)

    result = db.execute(
        query,
        {"group_id": group_id}
    )

    schedule = result.mappings().all()

    return schedule

@app.get("/staff")
def get_staff(db: Session = Depends(get_db)):

    query = text("""
        SELECT
            staff_id,
            staff_code,
            first_name,
            last_name,
            role,
            office_location
        FROM staff
        WHERE status = 'Active'
    """)

    result = db.execute(query)

    staff = result.mappings().all()

    return staff