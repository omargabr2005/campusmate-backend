"""
Advisor endpoints. These are the ONLY endpoints that return GPA.

Rules:
- Valid JWT and role 'Advisor' are required.
- The advisor is taken from the token, never from the URL or request body.
- An advisor only ever sees students whose advisor_id points to them.
- A student that is not theirs returns 404 (same as a student that does not exist).
- Every access is written to access_logs.
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth import require_advisor
from database import get_db

router = APIRouter(prefix="/advisor", tags=["advisor"])


def log_access(db: Session, user_id: int, request: Request, status_code: int):
    db.execute(
        text("""
            INSERT INTO access_logs (user_id, endpoint, method, status_code, ip_address)
            VALUES (:u, :e, :m, :s, :ip)
        """),
        {
            "u": user_id,
            "e": request.url.path[:150],
            "m": request.method,
            "s": status_code,
            "ip": request.client.host if request.client else None,
        },
    )
    db.commit()


@router.get("/students")
def my_students(
    request: Request,
    user: dict = Depends(require_advisor),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
                s.student_id,
                s.student_code,
                s.first_name,
                s.last_name,
                s.email,
                g.cumulative_gpa,
                g.credit_hours_earned
            FROM advisors a
            JOIN Students s
                ON s.advisor_id = a.advisor_id
            LEFT JOIN student_gpa g
                ON g.student_id = s.student_id
            WHERE a.staff_id = :staff_id
              AND a.status = 'Active'
            ORDER BY s.student_code
        """),
        {"staff_id": user["staff_id"]},
    ).mappings().all()

    log_access(db, user["user_id"], request, 200)
    return rows


@router.get("/students/{student_id}")
def my_student(
    student_id: int,
    request: Request,
    user: dict = Depends(require_advisor),
    db: Session = Depends(get_db),
):
    row = db.execute(
        text("""
            SELECT
                s.student_id,
                s.student_code,
                s.first_name,
                s.last_name,
                s.email,
                g.cumulative_gpa,
                g.credit_hours_earned
            FROM advisors a
            JOIN Students s
                ON s.advisor_id = a.advisor_id
            LEFT JOIN student_gpa g
                ON g.student_id = s.student_id
            WHERE a.staff_id = :staff_id
              AND a.status = 'Active'
              AND s.student_id = :student_id
        """),
        {"staff_id": user["staff_id"], "student_id": student_id},
    ).mappings().first()

    if row is None:
        log_access(db, user["user_id"], request, 404)
        raise HTTPException(404, "Student not found")

    log_access(db, user["user_id"], request, 200)
    return row
