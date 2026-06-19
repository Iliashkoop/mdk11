-- =====================================================
-- БИЛЕТ №12
-- Старшие по этажу, должники за 2+ месяца, комнаты с выбитыми стеклами + дети
-- Шифрование паспортов
-- =====================================================

-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Создаём таблицу комнат общежития
CREATE TABLE dorm_rooms (
    room_id SERIAL PRIMARY KEY,               -- Уникальный идентификатор комнаты
    room_number TEXT NOT NULL,                -- Номер комнаты
    floor INTEGER NOT NULL,                   -- Этаж
    has_broken_windows BOOLEAN NOT NULL DEFAULT FALSE,
    floor_senior_id INTEGER                   -- ID старшего по этажу (внешний ключ)
);

-- Создаём таблицу жильцов общежития
CREATE TABLE dorm_residents (
    resident_id SERIAL PRIMARY KEY, -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),  -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'),  -- Паспорт в формате 4010 123456
    room_id INTEGER NOT NULL 
        REFERENCES dorm_rooms(room_id) -- В какой комнате проживает
);

-- Создаём таблицу платежей
CREATE TABLE dorm_payments (
    payment_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор платежа
    resident_id INTEGER NOT NULL  REFERENCES dorm_residents(resident_id), -- Кто платит
    month DATE NOT NULL,   -- Месяц оплаты (первое число месяца)
    is_paid BOOLEAN NOT NULL  DEFAULT FALSE   -- Оплачено ли (по умолчанию - нет)
);

INSERT INTO dorm_rooms (room_number, floor, has_broken_windows) VALUES
('101', 1, FALSE),  ('102', 1, TRUE),   ('103', 1, FALSE),  
('201', 2, FALSE),  ('202', 2, TRUE),   ('203', 2, FALSE),  
('301', 3, FALSE),  ('302', 3, FALSE),  ('303', 3, TRUE),   
('401', 4, FALSE);

INSERT INTO dorm_residents (full_name, birth_date, phone, passport, room_id) VALUES
('Иван Петров', '1980-01-15', '812-111-0001', '4010 123456', 1),
('Мария Петрова', '1982-03-20', '812-111-0002', '4010 123457', 1),
('Петр Сидоров', '1975-07-25', '812-111-0003', '4010 123458', 2),
('Анна Сидорова', '2008-09-15', '812-111-0004', '4010 123459', 2),
('Сергей Иванов', '1988-11-30', '812-111-0005', '4010 123460', 3),
('Ольга Иванова', '1990-04-22', '812-111-0006', '4010 123461', 3),
('Алексей Смирнов', '1995-08-08', '812-111-0007', '4010 123462', 4),
('Елена Смирнова', '1998-12-25', '812-111-0008', '4010 123463', 4),
('Дмитрий Кузнецов', '2000-02-14', '812-111-0009', '4010 123464', 5),
('Татьяна Кузнецова', '2002-05-18', '812-111-0010', '4010 123465', 5);
-- Назначаем старших по этажам (первый жилец на каждом этаже)
UPDATE dorm_rooms SET floor_senior_id = 1 WHERE floor = 1;
UPDATE dorm_rooms SET floor_senior_id = 3 WHERE floor = 2;
UPDATE dorm_rooms SET floor_senior_id = 5 WHERE floor = 3;
UPDATE dorm_rooms SET floor_senior_id = 7 WHERE floor = 4;

INSERT INTO dorm_payments (resident_id, month, is_paid) VALUES
(1, '2024-01-01', TRUE), (1, '2024-02-01', FALSE), (1, '2024-03-01', FALSE),
(2, '2024-01-01', FALSE), (2, '2024-02-01', FALSE),
(3, '2024-01-01', TRUE), (3, '2024-02-01', TRUE),
(4, '2024-01-01', FALSE), (4, '2024-02-01', FALSE), (4, '2024-03-01', FALSE);

-- Запрос 1: Список старших по этажу
SELECT DISTINCT r.floor, dr.full_name AS floor_senior
FROM dorm_rooms r
JOIN dorm_residents dr ON r.floor_senior_id = dr.resident_id
ORDER BY r.floor;

-- Запрос 2: Должники за 2+ месяца
SELECT dr.full_name, COUNT(*) AS unpaid_months
FROM dorm_residents dr
JOIN dorm_payments dp ON dr.resident_id = dp.resident_id
WHERE dp.is_paid = FALSE
GROUP BY dr.resident_id, dr.full_name
HAVING COUNT(*) >= 2;

-- Запрос 3: Комнаты с выбитыми стёклами, в которых проживают дети
SELECT 
    r.floor,
    r.room_number,
    dr.full_name AS child_name,
    dr.birth_date,
    EXTRACT(YEAR FROM age(dr.birth_date)) AS age
FROM dorm_rooms r
JOIN dorm_residents dr ON r.room_id = dr.room_id
WHERE r.has_broken_windows = TRUE 
  AND EXTRACT(YEAR FROM age(dr.birth_date)) < 18
ORDER BY r.floor, r.room_number;

-- Запрос 4: Шифрование паспортных данных
CREATE OR REPLACE FUNCTION encrypt_passport_dorm(pass TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(pass::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;
-- Выводим ФИО и зашифрованный паспорт для всех жильцов
SELECT full_name, encrypt_passport_dorm(passport) AS encrypted_passport
FROM dorm_residents;
