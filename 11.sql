-- =====================================================
-- БИЛЕТ №11
-- Общежитие: средний возраст, старшие по комнатам, выбитые стекла,
-- автоудаление детей после 18 лет
-- =====================================================
-- Подключаем расширение для криптографии (на случай шифрования данных)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE dorm_rooms (
    room_id SERIAL PRIMARY KEY, -- Уникальный идентификатор комнаты
    room_number TEXT NOT NULL, -- Номер комнаты (например, "101")
    floor INTEGER NOT NULL,  -- Этаж
    has_broken_windows BOOLEAN NOT NULL DEFAULT FALSE, -- Есть ли выбитые стёкла (по умолчанию - нет)
    senior_resident_id INTEGER -- ID старшего по комнате (внешний ключ к residents)
);

CREATE TABLE dorm_residents (
    resident_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK ( phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK ( passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    room_id INTEGER NOT NULL REFERENCES dorm_rooms(room_id),       -- В какой комнате проживает
    is_child BOOLEAN NOT NULL   DEFAULT FALSE  -- Является ли ребёнком (по умолчанию - нет)
);

INSERT INTO dorm_rooms (room_number, floor, has_broken_windows) VALUES
('101', 1, FALSE), ('102', 1, TRUE), ('103', 1, FALSE),
('201', 2, FALSE), ('202', 2, TRUE), ('203', 2, FALSE),
('301', 3, FALSE), ('302', 3, FALSE), ('303', 3, TRUE),
('401', 4, FALSE);

INSERT INTO dorm_residents (full_name, birth_date, phone, passport, room_id, is_child) VALUES
('Иван Петров', '1980-01-15', '812-111-0001', '4010 123456', 1, FALSE),
('Мария Петрова', '2010-05-10', '812-111-0002', '4010 123457', 1, TRUE),
('Петр Сидоров', '1975-03-20', '812-111-0003', '4010 123458', 2, FALSE),
('Анна Сидорова', '2008-09-15', '812-111-0004', '4010 123459', 2, TRUE),
('Сергей Иванов', '1988-11-30', '812-111-0005', '4010 123460', 3, FALSE),
('Ольга Иванова', '2012-02-18', '812-111-0006', '4010 123461', 3, TRUE),
('Алексей Смирнов', '1990-04-22', '812-111-0007', '4010 123462', 4, FALSE),
('Елена Смирнова', '2015-06-12', '812-111-0008', '4010 123463', 4, TRUE),
('Дмитрий Кузнецов', '1995-08-08', '812-111-0009', '4010 123464', 5, FALSE),
('Татьяна Кузнецова', '2018-12-25', '812-111-0010', '4010 123465', 5, TRUE);

UPDATE dorm_rooms SET senior_resident_id = 1 WHERE room_id = 1;
UPDATE dorm_rooms SET senior_resident_id = 3 WHERE room_id = 2;
UPDATE dorm_rooms SET senior_resident_id = 5 WHERE room_id = 3;
UPDATE dorm_rooms SET senior_resident_id = 7 WHERE room_id = 4;
UPDATE dorm_rooms SET senior_resident_id = 9 WHERE room_id = 5;

-- Запрос 1: Средний возраст всех жильцов
SELECT ROUND(AVG(EXTRACT(YEAR FROM age(birth_date))), 1) AS avg_age FROM dorm_residents;

-- Запрос 2: Старшие по комнатам, где есть дети
SELECT r.room_number, dr.full_name AS senior_name
FROM dorm_rooms r
JOIN dorm_residents dr ON r.senior_resident_id = dr.resident_id
WHERE EXISTS (SELECT 1 FROM dorm_residents WHERE room_id = r.room_id AND is_child = TRUE);

-- Запрос 3: Комнаты с выбитыми стёклами
SELECT room_number FROM dorm_rooms WHERE has_broken_windows = TRUE;

-- Запрос 4: Автоудаление детей после 18 лет (функция)
CREATE OR REPLACE FUNCTION delete_adult_children()
RETURNS VOID AS $$
BEGIN
    DELETE FROM dorm_residents
    WHERE is_child = TRUE AND EXTRACT(YEAR FROM age(birth_date)) >= 18;
END;
$$ LANGUAGE plpgsql;

-- 1. Смотрим текущих жильцов
SELECT resident_id, full_name, birth_date, is_child, 
       EXTRACT(YEAR FROM age(birth_date)) AS age
FROM dorm_residents
ORDER BY resident_id;

-- 2. Вызываем функцию удаления
SELECT delete_adult_children();
-- Удалит всех детей старше 18 лет (в наших данных таких нет)

-- 3. Добавим "взрослого ребёнка" для проверки
INSERT INTO dorm_residents (full_name, birth_date, phone, passport, room_id, is_child) 
VALUES ('Тест Тестов', '2000-01-01', '812-111-0999', '4010 999999', 1, TRUE);

-- 4. Снова вызываем функцию
SELECT delete_adult_children()