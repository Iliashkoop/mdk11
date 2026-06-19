-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE streets (
    street_id SERIAL PRIMARY KEY,   -- Уникальный идентификатор улицы
    street_name TEXT NOT NULL -- Название улицы
);

CREATE TABLE buildings (
    building_id SERIAL PRIMARY KEY, -- Уникальный идентификатор здания
    street_id INTEGER NOT NULL REFERENCES streets(street_id), -- На какой улице находится
    building_number TEXT NOT NULL, -- Номер дома
    senior_full_name TEXT CHECK (senior_full_name = INITCAP(senior_full_name)) -- Староста дома (каждое слово с заглавной)
); 

CREATE TABLE apartments (
    apartment_id SERIAL PRIMARY KEY, -- Уникальный идентификатор квартиры
    building_id INTEGER NOT NULL REFERENCES buildings(building_id), -- В каком доме находится
    apartment_number TEXT NOT NULL -- Номер квартиры
); 

CREATE TABLE residents (
    resident_id SERIAL PRIMARY KEY, -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    gender CHAR(1) NOT NULL CHECK (gender IN ('М', 'Ж')),  -- Пол: только М или Ж
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    apartment_id INTEGER NOT NULL REFERENCES apartments(apartment_id), -- В какой квартире проживает
    is_pensioner BOOLEAN NOT NULL DEFAULT FALSE -- Является ли пенсионером (по умолчанию - нет)
);

INSERT INTO streets (street_name) VALUES 
('Ленина'),('Пушкина'),('Гоголя'),('Невская'),('Садовая'),
('Московская'),('Кирова'),('Советская'),('Мира'),('Строителей');

INSERT INTO buildings (street_id, building_number, senior_full_name) VALUES
(1,'1','Иван Смирнов'),(1,'3','Петр Сидоров'),(2,'5','Сергей Кузнецов'),
(2,'7','Анна Васильева'),(3,'2','Дмитрий Новиков'),(3,'4','Ольга Федорова'),
(4,'6','Алексей Морозов'),(5,'8','Татьяна Волкова'),(6,'10','Андрей Павлов'),(7,'12','Елена Соколова');

INSERT INTO apartments (building_id, apartment_number) VALUES
(1,'1'),(1,'2'),(1,'3'),(2,'10'),(2,'11'),
(2,'12'),(3,'5'),(3,'6'),(4,'20'),(4,'21');

INSERT INTO residents (full_name, gender, birth_date, phone, passport, apartment_id) VALUES
('Иван Петров', 'М', '1980-01-15', '812-111-0001', '4010 123456', 1),
('Мария Петрова', 'Ж', '1982-03-20', '812-111-0002', '4010 123457', 1),
('Петр Сидоров', 'М', '1960-05-10', '812-111-0003', '4010 123458', 2),
('Анна Сидорова', 'Ж', '1965-07-25', '812-111-0004', '4010 123459', 2),
('Сергей Иванов', 'М', '1970-11-30', '812-111-0005', '4010 123460', 3),
('Ольга Иванова', 'Ж', '2005-04-22', '812-111-0006', '4010 123461', 3),
('Дмитрий Кузнецов', 'М', '1990-08-08', '812-111-0007', '4010 123462', 4),
('Елена Кузнецова', 'Ж', '1995-12-25', '812-111-0008', '4010 123463', 4),
('Алексей Смирнов', 'М', '1988-02-14', '812-111-0009', '4010 123464', 5),
('Татьяна Смирнова', 'Ж', '2010-06-18', '812-111-0010', '4010 123465', 5);

-- Автоматически обновляем статус пенсионера на основе возраста
UPDATE residents SET is_pensioner = TRUE 
WHERE (gender = 'Ж' AND EXTRACT(YEAR FROM age(birth_date)) >= 55)
   OR (gender = 'М' AND EXTRACT(YEAR FROM age(birth_date)) >= 60);

-- Запрос 1: Информация о домах на улице Ленина
SELECT 
    b.building_number,
    b.floors,
    b.entrances,
    COUNT(a.apartment_id) AS apartments_count,
    b.senior_full_name
FROM buildings b
JOIN streets s ON b.street_id = s.street_id
LEFT JOIN apartments a ON b.building_id = a.building_id
WHERE s.street_name = 'Ленина'
GROUP BY b.building_id
ORDER BY b.building_number;

-- Запрос 2: Статистика по домам (пенсионеры и дети)
SELECT b.building_number,
       COUNT(CASE WHEN r.is_pensioner THEN 1 END) AS pensioners_count,
       COUNT(CASE WHEN EXTRACT(YEAR FROM age(r.birth_date)) < 18 THEN 1 END) AS children_count
FROM buildings b
JOIN apartments a ON b.building_id = a.building_id
JOIN residents r ON a.apartment_id = r.apartment_id
GROUP BY b.building_number;

-- Запрос 3: Количество жильцов с указанным телефоном
SELECT COUNT(DISTINCT r.resident_id) AS residents_with_phone
FROM residents r
WHERE r.phone IS NOT NULL;

-- Запрос 4: Шифрование телефонных номеров
CREATE OR REPLACE FUNCTION encrypt_phone(phone_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(phone_text::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;
-- Выводим имя жильца и зашифрованный номер телефона
SELECT full_name, encrypt_phone(phone) FROM residents;

