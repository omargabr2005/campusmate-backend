-- CampusMate: student<->group and course<->program become many-to-many
-- Run AFTER project.sql, advisor_gpa_migration.sql, rooms_competitions_migration.sql.
-- Run ONCE.


-- 1) Students can belong to MORE THAN ONE group
CREATE TABLE student_group_members (
    student_id INT NOT NULL,
    group_id INT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (student_id, group_id),

    FOREIGN KEY (student_id)
        REFERENCES Students(student_id)
        ON DELETE CASCADE,

    FOREIGN KEY (group_id)
        REFERENCES student_Groups(group_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_group_members_group ON student_group_members(group_id);

-- Keep any existing single-group assignments
INSERT INTO student_group_members (student_id, group_id)
SELECT student_id, group_id
FROM Students
WHERE group_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- The advisor_students view uses Students.group_id, so drop it first
DROP VIEW IF EXISTS advisor_students;

ALTER TABLE Students DROP COLUMN group_id;

CREATE VIEW advisor_students AS
SELECT
    a.advisor_id,
    a.staff_id AS advisor_staff_id,
    s.student_id,
    s.student_code,
    s.first_name,
    s.last_name,
    s.email,
    s.status
FROM advisors a
JOIN Students s
    ON s.advisor_id = a.advisor_id;


-- 2) Courses can belong to MORE THAN ONE program (Course_Programs already exists)
-- Keep any existing single-program assignments
INSERT INTO Course_Programs (course_id, program_id)
SELECT course_id, AcademicPrograms_id
FROM Courses
WHERE AcademicPrograms_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE Courses DROP COLUMN AcademicPrograms_id;