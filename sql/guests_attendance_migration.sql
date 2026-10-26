
CREATE TABLE IF NOT EXISTS guests (
    guest_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    national_id VARCHAR(14) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_guests_national_id
        CHECK (national_id ~ '^[0-9]{14}$')
);

CREATE TABLE IF NOT EXISTS campus_sessions (
    session_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_name VARCHAR(150) NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    room VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guest_attendance (
    attendance_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guest_id INTEGER NOT NULL REFERENCES guests(guest_id)
        ON DELETE CASCADE,
    session_id INTEGER NOT NULL REFERENCES campus_sessions(session_id)
        ON DELETE CASCADE,

    attendance_status VARCHAR(10) NOT NULL DEFAULT 'Registered'
        CHECK (attendance_status IN ('Registered', 'Present', 'Absent')),

    check_in_at TIMESTAMPTZ,
    check_out_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_guest_session UNIQUE (guest_id, session_id),

    -- Present requires a check-in time
    CONSTRAINT chk_present_has_checkin
        CHECK (attendance_status <> 'Present' OR check_in_at IS NOT NULL),

    -- check-out must come after check-in
    CONSTRAINT chk_checkout_after_checkin
        CHECK (check_out_at IS NULL
               OR (check_in_at IS NOT NULL AND check_out_at >= check_in_at))
);

-- "Who attended this session?" lookups
CREATE INDEX IF NOT EXISTS idx_guest_attendance_session
    ON guest_attendance (session_id);