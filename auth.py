"""
Authentication for CampusMate: login (JWT) + dependencies that protect endpoints.

Needs in .env:
    JWT_SECRET=<long random string, at least 32 chars>
    JWT_EXPIRE_MINUTES=60        # optional, default 60
"""
import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db  # importing database also loads .env

router = APIRouter(tags=["auth"])

ALGORITHM = "HS256"
TOKEN_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))
MAX_FAILED_ATTEMPTS = 5
MAX_PASSWORD_BYTES = 72  # bcrypt limit

bearer = HTTPBearer(auto_error=False)

# Used so a login for an unknown username takes the same time as a real one.
_DUMMY_HASH = bcrypt.hashpw(b"dummy-password", bcrypt.gensalt())


def _secret() -> str:
    secret = os.getenv("JWT_SECRET")
    if not secret or len(secret) < 32:
        raise HTTPException(503, "JWT_SECRET is not configured on the server")
    return secret


def _unauthorized(detail: str = "Invalid credentials") -> HTTPException:
    return HTTPException(401, detail, headers={"WWW-Authenticate": "Bearer"})


class LoginIn(BaseModel):
    username: str
    password: str


@router.post("/auth/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    row = db.execute(
        text("""
            SELECT u.user_id, u.password_hash, u.status,
                   u.failed_login_attempts, r.role_name
            FROM Users u
            JOIN Roles r ON r.role_id = u.role_id
            WHERE u.username = :u
        """),
        {"u": body.username},
    ).mappings().first()

    password = body.password.encode("utf-8")
    stored = row["password_hash"].encode("utf-8") if row else _DUMMY_HASH
    password_ok = len(password) <= MAX_PASSWORD_BYTES and bcrypt.checkpw(password, stored)

    # Same message for unknown user, wrong password, or inactive/locked account.
    if row is None or row["status"] != "Active":
        raise _unauthorized()

    if not password_ok:
        attempts = row["failed_login_attempts"] + 1
        new_status = "Locked" if attempts >= MAX_FAILED_ATTEMPTS else "Active"
        db.execute(
            text("""
                UPDATE Users
                SET failed_login_attempts = :a, status = :s
                WHERE user_id = :id
            """),
            {"a": attempts, "s": new_status, "id": row["user_id"]},
        )
        db.commit()
        raise _unauthorized()

    db.execute(
        text("""
            UPDATE Users
            SET failed_login_attempts = 0, last_login = CURRENT_TIMESTAMP
            WHERE user_id = :id
        """),
        {"id": row["user_id"]},
    )
    db.commit()

    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": str(row["user_id"]),
            "iat": now,
            "exp": now + timedelta(minutes=TOKEN_MINUTES),
        },
        _secret(),
        algorithm=ALGORITHM,
    )
    return {"access_token": token, "token_type": "bearer", "role": row["role_name"]}


def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    """Valid token + account still Active (so locking a user cuts access at once)."""
    if creds is None:
        raise _unauthorized("Not authenticated")

    try:
        payload = jwt.decode(creds.credentials, _secret(), algorithms=[ALGORITHM])
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise _unauthorized("Invalid or expired token")

    user = db.execute(
        text("""
            SELECT u.user_id, u.staff_id, u.status, r.role_name
            FROM Users u
            JOIN Roles r ON r.role_id = u.role_id
            WHERE u.user_id = :id
        """),
        {"id": user_id},
    ).mappings().first()

    if user is None or user["status"] != "Active":
        raise _unauthorized("Invalid or expired token")

    return dict(user)


def require_advisor(user: dict = Depends(get_current_user)):
    if user["role_name"] != "Advisor" or user["staff_id"] is None:
        raise HTTPException(403, "Advisors only")
    return user
