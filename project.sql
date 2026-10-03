CREATE DATABASE campusmate;
USE campusmate;


-- Departments

CREATE TABLE Departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(20) UNIQUE,
    status ENUM('Active', 'Inactive') DEFAULT 'Active'
);


-- AcademicPrograms

CREATE TABLE AcademicPrograms (
    AcademicPrograms_id INT AUTO_INCREMENT PRIMARY KEY,
    AcademicPrograms_name VARCHAR(100) NOT NULL,
    AcademicPrograms_code VARCHAR(10) UNIQUE NOT NULL,
    department_id INT NOT NULL,

    FOREIGN KEY (department_id)
        REFERENCES Departments(department_id)
);


-- student_Groups

CREATE TABLE student_Groups (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(50) NOT NULL,

    academic_level ENUM(
        'Freshman',
        'Sophomore',
        'Junior',
        'Senior'
    ) NOT NULL,

    status ENUM(
        'Active',
        'Inactive'
    ) DEFAULT 'Active',

    department_id INT,

    FOREIGN KEY (department_id)
        REFERENCES Departments(department_id)
);


-- Students

CREATE TABLE Students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    student_code VARCHAR(30) UNIQUE NOT NULL,

    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),

    email VARCHAR(100) UNIQUE NOT NULL,

    group_id INT,

    status ENUM(
        'Active',
        'Inactive'
    ) DEFAULT 'Active',

    advisor_id INT,

    FOREIGN KEY (group_id)
        REFERENCES student_Groups(group_id)
);


-- Courses

CREATE TABLE Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,

    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,

    credit_hours INT NOT NULL,

    status ENUM(
        'Active',
        'Inactive'
    ) DEFAULT 'Active',

    department_id INT,
    AcademicPrograms_id INT,

    FOREIGN KEY (department_id)
        REFERENCES Departments(department_id),

    FOREIGN KEY (AcademicPrograms_id)
        REFERENCES AcademicPrograms(AcademicPrograms_id)
);


-- Course_Programs

CREATE TABLE Course_Programs (
    course_id INT NOT NULL,
    program_id INT NOT NULL,

    requirement_type ENUM(
        'Core',
        'Elective'
    ) NOT NULL DEFAULT 'Core',

    PRIMARY KEY (course_id, program_id),

    FOREIGN KEY (course_id)
        REFERENCES Courses(course_id),

    FOREIGN KEY (program_id)
        REFERENCES AcademicPrograms(AcademicPrograms_id)
);


-- staff

CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,

    staff_code VARCHAR(20) UNIQUE NOT NULL,

    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,

    email VARCHAR(100) UNIQUE,

    role ENUM(
        'Doctor',
        'Teaching Assistant'
    ) NOT NULL,

    department_id INT,

    office_location VARCHAR(100),

    status ENUM(
        'Active',
        'Inactive'
    ) DEFAULT 'Active',

    FOREIGN KEY (department_id)
        REFERENCES Departments(department_id)
);


-- face_recognition

CREATE TABLE face_recognition (
    face_id INT AUTO_INCREMENT PRIMARY KEY,

    staff_code VARCHAR(20) NOT NULL,

    face_embedding BLOB NOT NULL,

    embedding_model VARCHAR(50) NOT NULL DEFAULT 'SFace',

    embedding_dimension INT NOT NULL DEFAULT 128,

    status ENUM(
        'Active',
        'Inactive'
    ) NOT NULL DEFAULT 'Active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_face_staff
        FOREIGN KEY (staff_code)
        REFERENCES staff(staff_code)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- Schedule

CREATE TABLE Schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,

    course_id INT NOT NULL,
    group_id INT NOT NULL,
    staff_id INT,

    day_of_week ENUM(
        'Saturday',
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday'
    ) NOT NULL,

    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    room VARCHAR(30),

    session_type ENUM(
        'Lecture',
        'Section'
    ) NOT NULL DEFAULT 'Lecture',

    semester VARCHAR(20),

    FOREIGN KEY (course_id)
        REFERENCES Courses(course_id),

    FOREIGN KEY (group_id)
        REFERENCES student_Groups(group_id),

    FOREIGN KEY (staff_id)
        REFERENCES staff(staff_id)
);


-- events

CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,

    title VARCHAR(150) NOT NULL,
    description TEXT,
    location VARCHAR(150),

    start_time DATETIME NOT NULL,
    end_time DATETIME,

    status ENUM(
        'Active',
        'Cancelled',
        'Finished'
    ) DEFAULT 'Active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    target_department_id INT,

    target_academic_level ENUM(
        'Freshman',
        'Sophomore',
        'Junior',
        'Senior'
    ),

    FOREIGN KEY (target_department_id)
        REFERENCES Departments(department_id)
);


-- office_hours

CREATE TABLE office_hours (
    office_hour_id INT AUTO_INCREMENT PRIMARY KEY,

    staff_id INT NOT NULL,

    day_of_week ENUM(
        'Saturday',
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday'
    ) NOT NULL,

    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    FOREIGN KEY (staff_id)
        REFERENCES staff(staff_id)
);


-- presence_log

CREATE TABLE presence_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,

    staff_id INT NOT NULL,

    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    status ENUM(
        'In',
        'Out'
    ) NOT NULL,

    FOREIGN KEY (staff_id)
        REFERENCES staff(staff_id)
);


-- Roles

CREATE TABLE Roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,

    role_name VARCHAR(30) UNIQUE NOT NULL
);


-- Users

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,

    username VARCHAR(50) UNIQUE NOT NULL,

    password_hash VARCHAR(255) NOT NULL,

    role_id INT NOT NULL,

    student_id INT,
    staff_id INT,

    status ENUM(
        'Active',
        'Inactive',
        'Locked'
    ) NOT NULL DEFAULT 'Active',

    last_login TIMESTAMP NULL,

    failed_login_attempts INT NOT NULL DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (role_id)
        REFERENCES Roles(role_id),

    FOREIGN KEY (student_id)
        REFERENCES Students(student_id),

    FOREIGN KEY (staff_id)
        REFERENCES staff(staff_id)
);


-- access_logs

CREATE TABLE access_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT,

    endpoint VARCHAR(150) NOT NULL,
    method VARCHAR(10) NOT NULL,

    status_code INT,

    ip_address VARCHAR(45),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES Users(user_id)
);


-- Enrollments

CREATE TABLE Enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NOT NULL,
    schedule_id INT NOT NULL,

    status ENUM(
        'Active',
        'Dropped',
        'Completed'
    ) DEFAULT 'Active',

    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id)
        REFERENCES Students(student_id),

    FOREIGN KEY (schedule_id)
        REFERENCES Schedule(schedule_id),

    UNIQUE (student_id, schedule_id)
);


-- Event_Attendance

CREATE TABLE Event_Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,

    event_id INT NOT NULL,
    student_id INT NOT NULL,

    checked_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (event_id)
        REFERENCES events(event_id),

    FOREIGN KEY (student_id)
        REFERENCES Students(student_id),

    UNIQUE (event_id, student_id)
);


-- Student Advisor

ALTER TABLE Students
ADD CONSTRAINT fk_student_advisor
    FOREIGN KEY (advisor_id)
    REFERENCES staff(staff_id);


-- office_hours_view

CREATE VIEW office_hours_view AS
SELECT
    oh.office_hour_id,
    s.staff_id,
    s.first_name,
    s.last_name,
    s.office_location,
    oh.day_of_week,
    oh.start_time,
    oh.end_time
FROM office_hours oh
JOIN staff s
    ON oh.staff_id = s.staff_id;


-- staff_current_status

CREATE VIEW staff_current_status AS
SELECT
    s.staff_id,
    s.first_name,
    s.last_name,
    s.office_location,
    p.status AS current_status,
    p.detected_at AS last_seen
FROM staff s
LEFT JOIN (
    SELECT pl1.*
    FROM presence_log pl1
    INNER JOIN (
        SELECT
            staff_id,
            MAX(detected_at) AS max_time
        FROM presence_log
        GROUP BY staff_id
    ) pl2
        ON pl1.staff_id = pl2.staff_id
        AND pl1.detected_at = pl2.max_time
) p
    ON s.staff_id = p.staff_id;