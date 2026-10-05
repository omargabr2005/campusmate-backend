"""
Face-recognition endpoints for CampusMate (for Omar's backend).

Wire-up in main.py (2 lines):
    from face_routes import router as face_router
    app.include_router(face_router)

Add to .env:
    FACE_API_KEY=<long random string>   # shared ONLY with the face-recognition device

Embedding format on the wire: base64 of 128 x float32 little-endian (512 bytes).
In MySQL it is stored as raw bytes in face_recognition.face_embedding (BLOB).
"""
import base64
import hmac
import os
from typing import Literal

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db

router = APIRouter()

EMBEDDING_DIM = 128
EMBEDDING_BYTES = EMBEDDING_DIM * 4  # float32


def require_api_key(x_api_key: str = Header(default="")):
    expected = os.getenv("FACE_API_KEY")
    if not expected:
        raise HTTPException(503, "FACE_API_KEY is not configured on the server")
    if not hmac.compare_digest(x_api_key, expected):
        raise HTTPException(401, "Invalid API key")


class EmbeddingIn(BaseModel):
    staff_code: str
    embedding_b64: str


class PresenceIn(BaseModel):
    staff_code: str
    status: Literal["In", "Out"]


def _staff_id(db: Session, staff_code: str) -> int:
    row = db.execute(
        text("SELECT staff_id FROM staff WHERE staff_code = :c AND status = 'Active'"),
        {"c": staff_code},
    ).first()
    if row is None:
        raise HTTPException(404, f"No active staff with code '{staff_code}'")
    return row[0]


@router.get("/face/embeddings", dependencies=[Depends(require_api_key)])
def list_embeddings(db: Session = Depends(get_db)):
    """The device downloads every active embedding at startup."""
    rows = db.execute(text("""
        SELECT f.staff_code, f.face_embedding, f.embedding_model, f.embedding_dimension
        FROM face_recognition f
        JOIN staff s ON s.staff_code = f.staff_code
        WHERE f.status = 'Active' AND s.status = 'Active'
    """)).mappings().all()
    return [
        {
            "staff_code": r["staff_code"],
            "embedding_b64": base64.b64encode(bytes(r["face_embedding"])).decode(),
            "model": r["embedding_model"],
            "dimension": r["embedding_dimension"],
        }
        for r in rows
    ]


@router.post("/face/embeddings", status_code=201, dependencies=[Depends(require_api_key)])
def add_embedding(body: EmbeddingIn, db: Session = Depends(get_db)):
    """Enrollment: one call per embedding sample (a person can have many rows)."""
    try:
        raw = base64.b64decode(body.embedding_b64, validate=True)
    except Exception:
        raise HTTPException(422, "embedding_b64 is not valid base64")
    if len(raw) != EMBEDDING_BYTES:
        raise HTTPException(422, f"Embedding must be {EMBEDDING_BYTES} bytes (128 x float32), got {len(raw)}")

    _staff_id(db, body.staff_code)  # 404 if unknown / inactive
    db.execute(
        text("INSERT INTO face_recognition (staff_code, face_embedding) VALUES (:c, :e)"),
        {"c": body.staff_code, "e": raw},
    )
    db.commit()
    return {"staff_code": body.staff_code, "stored": True}


@router.post("/face/presence", status_code=201, dependencies=[Depends(require_api_key)])
def log_presence(body: PresenceIn, db: Session = Depends(get_db)):
    """The device reports that a LIVE, recognized staff member came In / went Out."""
    staff_id = _staff_id(db, body.staff_code)
    db.execute(
        text("INSERT INTO presence_log (staff_id, status) VALUES (:s, :st)"),
        {"s": staff_id, "st": body.status},
    )
    db.commit()
    return {"staff_id": staff_id, "status": body.status}


@router.get("/staff/status")
def staff_status(db: Session = Depends(get_db)):
    """For the mobile app: who is in the office right now (uses the staff_current_status view)."""
    rows = db.execute(text("""
        SELECT staff_id, first_name, last_name, office_location, current_status, last_seen
        FROM staff_current_status
    """)).mappings().all()
    return rows
