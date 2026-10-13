-- CampusMate: DEMO data (fake). Run AFTER robot_info_migration.sql. Run ONCE.
-- Everything here is made up. Cleanup instructions are at the bottom.


-- Departments the demo rows point to
INSERT INTO Departments (department_name, department_code) VALUES
    ('Computer Science', 'CS'),
    ('Information Systems', 'IS'),
    ('Artificial Intelligence', 'AI')
ON CONFLICT DO NOTHING;


-- Buildings and floors (building codes start with DEMO- so they are easy to remove)
INSERT INTO buildings (building_name, building_code) VALUES
    ('Main Building', 'DEMO-MAIN'),
    ('Engineering Building', 'DEMO-ENG')
ON CONFLICT DO NOTHING;

INSERT INTO floors (building_id, floor_number)
SELECT b.building_id, f.n
FROM buildings b
CROSS JOIN (VALUES (0), (1), (2), (3)) AS f(n)
WHERE b.building_code IN ('DEMO-MAIN', 'DEMO-ENG')
ON CONFLICT DO NOTHING;


-- 10 rooms
INSERT INTO rooms (floor_id, room_code, room_type, capacity,
                   directions_from_robot, has_step_free_route, step_free_directions)
SELECT f.floor_id, v.room_code, v.room_type, v.capacity,
       v.directions, v.step_free, v.step_free_directions
FROM (VALUES
    ('DEMO-MAIN', 0, 'A-001', 'Lecture Hall', 200,
     'من الروبوت امشي مستقيم لحد المدخل الرئيسي، القاعة على إيدك اليمين.',
     TRUE, 'نفس الطريق، الدور أرضي ومفيش سلالم.'),
    ('DEMO-MAIN', 1, 'A-101', 'Lecture Hall', 120,
     'اطلع السلم الرئيسي للدور الأول وانعطف يسار، القاعة تاني باب.',
     TRUE, 'خد الأسانسير اللي جنب المدخل للدور الأول وانعطف يسار.'),
    ('DEMO-MAIN', 1, 'A-102', 'Section Room', 40,
     'اطلع السلم الرئيسي للدور الأول وانعطف يسار، القاعة آخر الممر.',
     TRUE, 'خد الأسانسير للدور الأول وكمل لآخر الممر على الشمال.'),
    ('DEMO-MAIN', 1, 'A-103', 'Office', 4,
     'اطلع السلم الرئيسي للدور الأول وانعطف يمين، المكتب أول باب.',
     TRUE, 'خد الأسانسير للدور الأول وانعطف يمين، المكتب أول باب.'),
    ('DEMO-MAIN', 2, 'A-201', 'Lab', 30,
     'اطلع السلم الرئيسي للدور التاني، المعمل قدام السلم مباشرة.',
     FALSE, NULL),
    ('DEMO-MAIN', 2, 'A-202', 'Office', 4,
     'اطلع السلم الرئيسي للدور التاني وانعطف يسار، المكتب تالت باب.',
     TRUE, 'خد الأسانسير للدور التاني وانعطف يسار، المكتب تالت باب.'),
    ('DEMO-ENG', 0, 'B-001', 'Lab', 35,
     'اخرج من المبنى الرئيسي وامشي ناحية مبنى الهندسة، المعمل في الدور الأرضي.',
     TRUE, 'نفس الطريق، الممر مسطح من غير سلالم.'),
    ('DEMO-ENG', 1, 'B-101', 'Section Room', 45,
     'ادخل مبنى الهندسة واطلع السلم للدور الأول، القاعة على اليمين.',
     FALSE, NULL),
    ('DEMO-ENG', 2, 'B-201', 'Office', 4,
     'ادخل مبنى الهندسة واطلع السلم للدور التاني وانعطف يمين، المكتب أول باب.',
     TRUE, 'ادخل مبنى الهندسة وخد الأسانسير للدور التاني وانعطف يمين.'),
    ('DEMO-ENG', 3, 'B-301', 'Lecture Hall', 100,
     'ادخل مبنى الهندسة واطلع السلم للدور التالت، القاعة آخر الممر.',
     FALSE, NULL)
) AS v(building_code, floor_number, room_code, room_type, capacity,
       directions, step_free, step_free_directions)
JOIN buildings b ON b.building_code = v.building_code
JOIN floors f ON f.building_id = b.building_id AND f.floor_number = v.floor_number
ON CONFLICT DO NOTHING;


-- 10 courses (English name, Arabic name, academic year, department)
INSERT INTO Courses (course_code, course_name, course_name_ar, credit_hours, academic_year, department_id)
SELECT v.course_code, v.name_en, v.name_ar, v.credit_hours, v.academic_year, d.department_id
FROM (VALUES
    ('CS101', 'Introduction to Programming', 'مقدمة في البرمجة', 3, 1, 'CS'),
    ('CS102', 'Discrete Mathematics', 'الرياضيات المتقطعة', 3, 1, 'CS'),
    ('CS201', 'Data Structures', 'هياكل البيانات', 3, 2, 'CS'),
    ('CS202', 'Object-Oriented Programming', 'البرمجة كائنية التوجه', 3, 2, 'CS'),
    ('CS301', 'Algorithms', 'تصميم وتحليل الخوارزميات', 3, 3, 'CS'),
    ('IS201', 'Database Systems', 'نظم قواعد البيانات', 3, 2, 'IS'),
    ('IS301', 'Systems Analysis and Design', 'تحليل وتصميم النظم', 3, 3, 'IS'),
    ('AI201', 'Introduction to Artificial Intelligence', 'مقدمة في الذكاء الاصطناعي', 3, 2, 'AI'),
    ('AI301', 'Machine Learning', 'تعلم الآلة', 3, 3, 'AI'),
    ('AI401', 'Natural Language Processing', 'معالجة اللغات الطبيعية', 3, 4, 'AI')
) AS v(course_code, name_en, name_ar, credit_hours, academic_year, dept_code)
JOIN Departments d ON d.department_code = v.dept_code
ON CONFLICT DO NOTHING;


-- Course nicknames (what students actually call them)
INSERT INTO course_aliases (course_id, alias)
SELECT c.course_id, v.alias
FROM (VALUES
    ('CS101', 'برمجة 1'),
    ('CS101', 'انترو'),
    ('CS102', 'ديسكريت'),
    ('CS201', 'داتا ستركشر'),
    ('CS201', 'DS'),
    ('CS202', 'OOP'),
    ('CS202', 'اوبجكت'),
    ('CS301', 'الجوريثمز'),
    ('IS201', 'داتا بيز'),
    ('IS201', 'DB'),
    ('IS301', 'سيستم انالسز'),
    ('AI201', 'ايه اي'),
    ('AI301', 'ML'),
    ('AI301', 'ماشين لرنينج'),
    ('AI401', 'NLP')
) AS v(course_code, alias)
JOIN Courses c ON c.course_code = v.course_code
ON CONFLICT DO NOTHING;


-- 10 staff members (6 doctors + 4 teaching assistants), offices linked to rooms
INSERT INTO staff (staff_code, first_name, last_name, email, role,
                   department_id, office_room_id, office_location, title)
SELECT v.staff_code, v.first_name, v.last_name, v.email, v.role,
       d.department_id, r.room_id, r.room_code, v.title
FROM (VALUES
    ('DEMO-DR01', 'محمد', 'السيد', 'demo.dr01@example.com', 'Doctor', 'CS', 'A-103', 'أ.د.'),
    ('DEMO-DR02', 'منى', 'عبد الله', 'demo.dr02@example.com', 'Doctor', 'CS', 'A-202', 'د.'),
    ('DEMO-DR03', 'خالد', 'ابراهيم', 'demo.dr03@example.com', 'Doctor', 'IS', 'B-201', 'أ.د.'),
    ('DEMO-DR04', 'هبة', 'مصطفى', 'demo.dr04@example.com', 'Doctor', 'IS', 'A-202', 'د.'),
    ('DEMO-DR05', 'عمرو', 'فتحي', 'demo.dr05@example.com', 'Doctor', 'AI', 'B-201', 'د.'),
    ('DEMO-DR06', 'سارة', 'عادل', 'demo.dr06@example.com', 'Doctor', 'AI', 'A-103', 'أ.د.'),
    ('DEMO-TA01', 'يوسف', 'كمال', 'demo.ta01@example.com', 'Teaching Assistant', 'CS', 'A-202', 'م.'),
    ('DEMO-TA02', 'نور', 'حسين', 'demo.ta02@example.com', 'Teaching Assistant', 'CS', 'A-202', 'م.م.'),
    ('DEMO-TA03', 'مريم', 'سمير', 'demo.ta03@example.com', 'Teaching Assistant', 'IS', 'B-201', 'م.'),
    ('DEMO-TA04', 'آدم', 'رضا', 'demo.ta04@example.com', 'Teaching Assistant', 'AI', 'B-201', 'م.م.')
) AS v(staff_code, first_name, last_name, email, role, dept_code, office_code, title)
JOIN Departments d ON d.department_code = v.dept_code
JOIN rooms r ON r.room_code = v.office_code
JOIN floors f ON f.floor_id = r.floor_id
JOIN buildings b ON b.building_id = f.building_id AND b.building_code LIKE 'DEMO-%'
ON CONFLICT DO NOTHING;


-- Check: expect 10 / 10 / 10 / 15
SELECT
    (SELECT COUNT(*) FROM rooms_directory WHERE room_code IN
        ('A-001','A-101','A-102','A-103','A-201','A-202','B-001','B-101','B-201','B-301')) AS rooms,
    (SELECT COUNT(*) FROM courses_directory) AS courses,
    (SELECT COUNT(*) FROM staff_directory WHERE staff_code LIKE 'DEMO-%') AS staff,
    (SELECT COUNT(*) FROM course_aliases) AS aliases;


-- CLEANUP (run these when the demo data is no longer needed; order matters):
-- DELETE FROM staff WHERE staff_code LIKE 'DEMO-%';
-- DELETE FROM buildings WHERE building_code LIKE 'DEMO-%';   -- also removes floors and rooms
-- DELETE FROM Courses WHERE course_code IN
--   ('CS101','CS102','CS201','CS202','CS301','IS201','IS301','AI201','AI301','AI401');  -- aliases go too