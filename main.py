from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from face_routes import router as face_router
from database import get_db


app = FastAPI()
app.include_router(face_router)

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

    # PostgreSQL has no FIELD(); a CASE expression gives the same day order.
    # Room comes from the rooms table when set, otherwise from the old text column.
    query = text("""
        SELECT
            sc.schedule_id,
            sc.day_of_week,
            sc.start_time,
            sc.end_time,
            c.course_code,
            c.course_name,
            COALESCE(r.room_code, sc.room) AS room,
            f.floor_number,
            b.building_name,
            sc.session_type,
            sc.semester
        FROM Schedule sc
        JOIN Courses c
            ON sc.course_id = c.course_id
        LEFT JOIN rooms r
            ON sc.room_id = r.room_id
        LEFT JOIN floors f
            ON r.floor_id = f.floor_id
        LEFT JOIN buildings b
            ON f.building_id = b.building_id
        WHERE sc.group_id = :group_id
        ORDER BY
            CASE sc.day_of_week
                WHEN 'Saturday' THEN 1
                WHEN 'Sunday' THEN 2
                WHEN 'Monday' THEN 3
                WHEN 'Tuesday' THEN 4
                WHEN 'Wednesday' THEN 5
                WHEN 'Thursday' THEN 6
            END,
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