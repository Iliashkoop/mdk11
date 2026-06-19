-- =====================================================
-- БИЛЕТ №14
-- Комнаты с выбитыми стеклами + дети, сводка по этажам (мужчины/женщины),
-- свободные места в комнатах, шифрование телефонов
-- =====================================================
-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE dorm_rooms ( 
    room_id SERIAL PRIMARY KEY, -- Уникальный идентификатор комнаты
    room_number TEXT NOT NULL, -- Номер комнаты
    floor INTEGER NOT NULL, -- Этаж
    max_capacity INTEGER NOT NULL DEFAULT 4, -- Максимальная вместимость комнаты (по умолчанию 4)
    has_broken_windows BOOLEAN NOT NULL DEFAULT FALSE  -- Есть ли выбитые стёкла
);

CREATE TABLE dorm_residents (
    resident_id SERIAL PRIMARY KEY, -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    gender CHAR(1) NOT NULL CHECK (gender IN ('М', 'Ж')), -- Пол: только М или Ж
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    room_id INTEGER NOT NULL REFERENCES dorm_rooms(room_id), -- В какой комнате проживает
    is_child BOOLEAN NOT NULL DEFAULT FALSE -- Является ли ребёнком
);

INSERT INTO dorm_rooms (room_number, floor, max_capacity, has_broken_windows) VALUES
('101',1,4,FALSE),('102',1,4,TRUE),('103',1,4,FALSE),('104',1,4,FALSE),
('201',2,4,FALSE),('202',2,4,TRUE),('203',2,4,FALSE),('204',2,4,FALSE),
('301',3,4,FALSE),('302',3,4,FALSE);

INSERT INTO dorm_residents (full_name, gender, birth_date, phone, passport, room_id, is_child) VALUES
('Иван Петров', 'М', '1980-01-15', '812-111-0001', '4010 123456', 1, FALSE),
('Мария Петрова', 'Ж', '1982-03-20', '812-111-0002', '4010 123457', 1, FALSE),
('Алексей Петров', 'М', '2010-05-10', '812-111-0003', '4010 123458', 1, TRUE),
('Ольга Смирнова', 'Ж', '1975-07-25', '812-111-0004', '4010 123459', 2, FALSE),
('Дмитрий Смирнов', 'М', '2005-09-15', '812-111-0005', '4010 123460', 2, TRUE),
('Сергей Иванов', 'М', '1990-11-30', '812-111-0006', '4010 123461', 3, FALSE),
('Анна Иванова', 'Ж', '2008-02-18', '812-111-0007', '4010 123462', 3, TRUE),
('Елена Кузнецова', 'Ж', '1988-04-22', '812-111-0008', '4010 123463', 4, FALSE),
('Павел Кузнецов', 'М', '2015-06-12', '812-111-0009', '4010 123464', 4, TRUE),
('Татьяна Соколова', 'Ж', '1995-08-08', '812-111-0010', '4010 123465', 5, FALSE);

-- Запрос 1: Комнаты с выбитыми стёклами, в которых проживают дети
SELECT DISTINCT r.room_number, r.floor
FROM dorm_rooms r
JOIN dorm_residents dr ON r.room_id = dr.room_id
WHERE r.has_broken_windows = TRUE AND dr.is_child = TRUE;

-- Запрос 2: Сводка по этажам (мужчины/женщины)
SELECT r.floor,
       COUNT(CASE WHEN dr.gender = 'М' THEN 1 END) AS men_count,
       COUNT(CASE WHEN dr.gender = 'Ж' THEN 1 END) AS women_count
FROM dorm_rooms r
JOIN dorm_residents dr ON r.room_id = dr.room_id
GROUP BY r.floor
ORDER BY r.floor;

-- Запрос 3: Свободные места в комнатах
SELECT r.room_number, r.floor, r.max_capacity, COUNT(dr.resident_id) AS current_residents,
       r.max_capacity - COUNT(dr.resident_id) AS free_spaces
FROM dorm_rooms r
LEFT JOIN dorm_residents dr ON r.room_id = dr.room_id
GROUP BY r.room_id, r.room_number, r.floor, r.max_capacity
HAVING r.max_capacity - COUNT(dr.resident_id) > 0
ORDER BY r.floor, r.room_number;

-- Запрос 4: Шифрование телефонов
CREATE OR REPLACE FUNCTION encrypt_phone_dorm(phone_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(phone_text::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;
-- Выводим ФИО и зашифрованный телефон для всех жильцов
SELECT full_name, encrypt_phone_dorm(phone) FROM dorm_residents;
