"""
Create an advisor login for an existing staff member.

Usage (from the project folder, venv active):
    python create_advisor.py STAFF_CODE USERNAME

The password is typed at a hidden prompt, so it never appears in the
terminal history, the chat, or the repository.
"""
import sys
from getpass import getpass

import bcrypt
from sqlalchemy import text

from database import engine

MIN_LENGTH = 10
MAX_BYTES = 72  # bcrypt limit


def main():
    if len(sys.argv) != 3:
        print("Usage: python create_advisor.py STAFF_CODE USERNAME")
        sys.exit(1)

    staff_code, username = sys.argv[1], sys.argv[2]

    password = getpass("Password: ")
    if getpass("Repeat password: ") != password:
        print("Passwords do not match.")
        sys.exit(1)
    if len(password) < MIN_LENGTH:
        print(f"Password must be at least {MIN_LENGTH} characters.")
        sys.exit(1)
    if len(password.encode("utf-8")) > MAX_BYTES:
        print(f"Password must be at most {MAX_BYTES} bytes.")
        sys.exit(1)

    password_hash = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

    with engine.begin() as conn:
        staff = conn.execute(
            text("SELECT staff_id FROM staff WHERE staff_code = :c AND status = 'Active'"),
            {"c": staff_code},
        ).first()
        if staff is None:
            print(f"No active staff member with code '{staff_code}'.")
            sys.exit(1)
        staff_id = staff[0]

        role = conn.execute(
            text("SELECT role_id FROM Roles WHERE role_name = 'Advisor'")
        ).first()
        if role is None:
            print("Role 'Advisor' not found. Run sql/advisor_gpa_migration.sql first.")
            sys.exit(1)

        conn.execute(
            text("INSERT INTO advisors (staff_id) VALUES (:s) ON CONFLICT (staff_id) DO NOTHING"),
            {"s": staff_id},
        )

        try:
            conn.execute(
                text("""
                    INSERT INTO Users (username, password_hash, role_id, staff_id)
                    VALUES (:u, :h, :r, :s)
                """),
                {"u": username, "h": password_hash, "r": role[0], "s": staff_id},
            )
        except Exception as exc:
            print(f"Could not create the user (username already taken?): {exc.__class__.__name__}")
            sys.exit(1)

    print(f"Advisor account '{username}' created for staff '{staff_code}'.")


if __name__ == "__main__":
    main()
