-- =====================================================
-- БИЛЕТ №4
-- Жилищная контора: приватизированные квартиры, состав семьи, многодетные
-- =====================================================

CREATE TABLE streets (
    street_id SERIAL PRIMARY KEY, -- Уникальный идентификатор улицы
    street_name TEXT NOT NULL -- Название улицы
);

CREATE TABLE buildings (
    building_id SERIAL PRIMARY KEY, -- Уникальный идентификатор здания
    street_id INTEGER NOT NULL REFERENCES streets(street_id), -- На какой улице находится
    building_number TEXT NOT NULL -- Номер дома (может быть с корпусом)
);

CREATE TABLE apartments (
    apartment_id SERIAL PRIMARY KEY, -- Уникальный идентификатор квартиры
    building_id INTEGER NOT NULL REFERENCES buildings(building_id), -- В каком доме находится
    apartment_number TEXT NOT NULL, -- Номер квартиры
    is_privatized BOOLEAN NOT NULL DEFAULT FALSE -- Приватизирована ли (по умолчанию - нет)
);

CREATE TABLE residents (
    resident_id SERIAL PRIMARY KEY, -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    apartment_id INTEGER NOT NULL REFERENCES apartments(apartment_id)  -- В какой квартире проживает
);

INSERT INTO streets (street_name) VALUES 
('Ленина'),('Пушкина'),('Гоголя'),('Невская'),('Садовая'),
('Московская'),('Кирова'),('Советская'),('Мира'),('Строителей');

INSERT INTO buildings (street_id, building_number) VALUES
(1,'1'),(1,'3'),(2,'5'),(2,'7'),(3,'2'),(3,'4'),(4,'6'),(5,'8'),(6,'10'),(7,'12');

INSERT INTO apartments (building_id, apartment_number, is_privatized) VALUES
(1,'1',TRUE),(1,'2',FALSE),(1,'3',TRUE),(2,'10',TRUE),(2,'11',FALSE),
(2,'12',TRUE),(3,'5',TRUE),(3,'6',FALSE),(4,'20',TRUE),(4,'21',TRUE);

INSERT INTO residents (full_name, birth_date, phone, passport, apartment_id) VALUES
('Иван Петров', '1980-01-15', '812-111-0001', '4010 123456', 1),
('Мария Петрова', '1982-03-20', '812-111-0002', '4010 123457', 1),
('Алексей Петров', '2010-05-10', '812-111-0003', '4010 123458', 1),
('Ольга Смирнова', '1975-07-25', '812-111-0004', '4010 123459', 2),
('Дмитрий Смирнов', '2005-09-15', '812-111-0005', '4010 123460', 2),
('Елена Кузнецова', '1988-11-30', '812-111-0006', '4010 123461', 3),
('Андрей Кузнецов', '2015-02-18', '812-111-0007', '4010 123462', 3),
('Татьяна Новикова', '1990-04-22', '812-111-0008', '4010 123463', 4),
('Сергей Новиков', '1987-06-12', '812-111-0009', '4010 123464', 4),
('Наталья Морозова', '1995-08-08', '812-111-0010', '4010 123465', 5);

-- Запрос 1: Список всех приватизированных квартир
SELECT s.street_name, b.building_number, a.apartment_number
FROM apartments a
JOIN buildings b ON a.building_id = b.building_id
JOIN streets s ON b.street_id = s.street_id
WHERE a.is_privatized = TRUE;

-- Запрос 2: Поиск жильцов по точному адресу
SELECT r.*
FROM residents r
JOIN apartments a ON r.apartment_id = a.apartment_id
JOIN buildings b ON a.building_id = b.building_id
JOIN streets s ON b.street_id = s.street_id
WHERE s.street_name = 'Ленина' AND b.building_number = '1' AND a.apartment_number = '1';

-- Запрос 3: Поиск квартир с несовершеннолетними жильцами (дети до 18 лет)
SELECT s.street_name, b.building_number, a.apartment_number, COUNT(*) AS children_count
FROM residents r
JOIN apartments a ON r.apartment_id = a.apartment_id
JOIN buildings b ON a.building_id = b.building_id
JOIN streets s ON b.street_id = s.street_id
WHERE EXTRACT(YEAR FROM age(r.birth_date)) < 18
GROUP BY a.apartment_id, s.street_name, b.building_number, a.apartment_number
HAVING COUNT(*) >= 1;

-- Запрос 4 (бэкап) - в командной строке:
-- pg_dump -U postgres -F c -b -v -f "C:/backup/exam_backup.backup" имя_базы


