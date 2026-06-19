-- =====================================================
-- БИЛЕТ №13
-- Общежитие: проживающие в комнате, дети до 7 лет без ДДУ,
-- общее количество детей семейных студентов, резервная копия
-- =====================================================

CREATE TABLE dorm_rooms (
    room_id SERIAL PRIMARY KEY, -- Уникальный идентификатор комнаты
    room_number TEXT NOT NULL, -- Номер комнаты
    floor INTEGER NOT NULL -- Этаж
);

CREATE TABLE dorm_residents (
    resident_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    room_id INTEGER NOT NULL REFERENCES dorm_rooms(room_id), -- В какой комнате проживает
    is_family_student BOOLEAN NOT NULL DEFAULT FALSE, -- Является ли ребёнком семейного студента
    attends_kindergarten BOOLEAN NOT NULL DEFAULT FALSE -- Посещает ли детский сад (ДДУ)
);

INSERT INTO dorm_rooms (room_number, floor) VALUES
('101',1),('102',1),('103',1),('201',2),('202',2),
('203',2),('301',3),('302',3),('303',3),('401',4);

INSERT INTO dorm_residents (full_name, birth_date, phone, passport, room_id, is_family_student, attends_kindergarten) VALUES
('Иван Петров', '1980-01-15', '812-111-0001', '4010 123456', 1, FALSE, FALSE),
('Мария Петрова', '1982-03-20', '812-111-0002', '4010 123457', 1, FALSE, FALSE),
('Алексей Петров', '2018-05-10', '812-111-0003', '4010 123458', 1, TRUE, FALSE),
('Ольга Смирнова', '1975-07-25', '812-111-0004', '4010 123459', 2, FALSE, FALSE),
('Дмитрий Смирнов', '2019-09-15', '812-111-0005', '4010 123460', 2, TRUE, TRUE),
('Сергей Иванов', '1995-11-30', '812-111-0006', '4010 123461', 3, FALSE, FALSE),
('Анна Иванова', '2020-02-18', '812-111-0007', '4010 123462', 3, TRUE, FALSE),
('Елена Кузнецова', '1988-04-22', '812-111-0008', '4010 123463', 4, TRUE, FALSE),
('Павел Кузнецов', '2017-06-12', '812-111-0009', '4010 123464', 4, TRUE, TRUE),
('Татьяна Соколова', '1998-08-08', '812-111-0010', '4010 123465', 5, FALSE, FALSE);

-- Запрос 1: Жильцы, проживающие в комнате 101
SELECT r.full_name, r.birth_date, r.phone
FROM dorm_residents r
WHERE r.room_id = (SELECT room_id FROM dorm_rooms WHERE room_number = '101');

-- Запрос 3: Общее количество детей семейных студентов
SELECT full_name, birth_date, EXTRACT(YEAR FROM age(birth_date)) AS age
FROM dorm_residents
WHERE EXTRACT(YEAR FROM age(birth_date)) < 7
  AND is_family_student = TRUE
  AND attends_kindergarten = FALSE;

-- Запрос 3
SELECT COUNT(*) AS total_children_of_family_students
FROM dorm_residents
WHERE is_family_student = TRUE;

-- Запрос 4 (бэкап) - в командной строке:
-- pg_dump -U postgres -F c -b -v -f "C:/backup/exam_backup.backup" имя_базы

