-- =====================================================
-- БИЛЕТ №5
-- Жилищная контора: дома, квартиры, жильцы, разграничение доступа
-- =====================================================

CREATE TABLE streets (
    street_id SERIAL PRIMARY KEY, -- Уникальный идентификатор улицы
    street_name TEXT NOT NULL -- Название улицы
);

CREATE TABLE buildings (
    building_id SERIAL PRIMARY KEY, -- Уникальный идентификатор здания
    street_id INTEGER NOT NULL REFERENCES streets(street_id), -- На какой улице находится
    building_number TEXT NOT NULL, -- Номер дома
    floors INTEGER, -- Количество этажей (может быть NULL)
    entrances INTEGER, -- Количество подъездов (может быть NULL)
    senior_full_name TEXT CHECK (senior_full_name = INITCAP(senior_full_name)) -- Староста дома (каждое слово с заглавной)
);

CREATE TABLE apartments (
    apartment_id SERIAL PRIMARY KEY, -- Уникальный идентификатор квартиры
    building_id INTEGER NOT NULL REFERENCES buildings(building_id), -- В каком доме находится
    apartment_number TEXT NOT NULL, -- Номер квартиры
    area NUMERIC(8,2) NOT NULL, -- Площадь квартиры (кв.м) с 2 знаками
    rooms_count INTEGER NOT NULL -- Количество комнат
);

CREATE TABLE residents (
    resident_id SERIAL PRIMARY KEY, -- Уникальный идентификатор жильца
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    apartment_id INTEGER NOT NULL REFERENCES apartments(apartment_id) -- В какой квартире проживает
);

INSERT INTO streets (street_name) VALUES 
('Ленина'),('Пушкина'),('Гоголя'),('Невская'),('Садовая'),
('Московская'),('Кирова'),('Советская'),('Мира'),('Строителей');

INSERT INTO buildings (street_id, building_number, floors, entrances, senior_full_name) VALUES
(1,'1',5,2,'Иван Смирнов'),(1,'3',9,3,'Петр Сидоров'),(2,'5',3,1,'Сергей Кузнецов'),
(2,'7',12,4,'Анна Васильева'),(3,'2',5,2,'Дмитрий Новиков'),(3,'4',9,3,'Ольга Федорова'),
(4,'6',3,1,'Алексей Морозов'),(5,'8',16,5,'Татьяна Волкова'),(6,'10',5,2,'Андрей Павлов'),(7,'12',9,3,'Елена Соколова');

INSERT INTO apartments (building_id, apartment_number, area, rooms_count) VALUES
(1,'1',55,3),(1,'2',38,2),(1,'3',72,4),(2,'10',45,2),(2,'11',68,3),
(2,'12',35,1),(3,'5',28,2),(3,'6',52,3),(4,'20',42,2),(4,'21',88,4);

INSERT INTO residents (full_name, birth_date, phone, passport, apartment_id) VALUES
('Иван Петров', '1980-01-15', '812-111-0001', '4010 123456', 1),
('Мария Петрова', '1982-03-20', '812-111-0002', '4010 123457', 1),
('Алексей Петров', '2010-05-10', '812-111-0003', '4010 123458', 1),
('Елена Петрова', '2012-07-12', '812-111-0004', '4010 123459', 1),
('Ольга Смирнова', '1975-07-25', '812-111-0005', '4010 123460', 2),
('Дмитрий Смирнов', '2005-09-15', '812-111-0006', '4010 123461', 2),
('Елена Кузнецова', '1988-11-30', '812-111-0007', '4010 123462', 3),
('Андрей Кузнецов', '2015-02-18', '812-111-0008', '4010 123463', 3),
('Татьяна Новикова', '1990-04-22', '812-111-0009', '4010 123464', 4),
('Сергей Новиков', '1987-06-12', '812-111-0010', '4010 123465', 4);

-- Запрос 1: Поиск трёхкомнатных квартир на Ленина 1
SELECT s.street_name, b.building_number, a.apartment_number
FROM apartments a
JOIN buildings b ON a.building_id = b.building_id
JOIN streets s ON b.street_id = s.street_id
WHERE a.rooms_count = 3 AND s.street_name = 'Ленина' AND b.building_number = '1';

-- Запрос 2: Информация о домах на улице Ленина
SELECT b.building_number, b.floors, b.entrances, b.senior_full_name
FROM buildings b
JOIN streets s ON b.street_id = s.street_id
WHERE s.street_name = 'Ленина';

-- Запрос 3: Переполненные и малогабаритные квартиры
SELECT s.street_name, b.building_number, a.apartment_number, COUNT(r.resident_id) AS cnt, a.area
FROM apartments a
JOIN buildings b ON a.building_id = b.building_id
JOIN streets s ON b.street_id = s.street_id
LEFT JOIN residents r ON a.apartment_id = r.apartment_id
GROUP BY a.apartment_id, s.street_name, b.building_number, a.apartment_number, a.area
HAVING COUNT(r.resident_id) > 4 AND a.area < 30;

-- Запрос 4: Разграничение доступа к данным
CREATE USER chairman WITH PASSWORD 'chairman123';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO chairman;

CREATE USER senior WITH PASSWORD 'senior123';
GRANT SELECT ON apartments, residents TO senior;

ALTER TABLE apartments ENABLE ROW LEVEL SECURITY;
CREATE POLICY senior_policy ON apartments USING (building_id = 1);
ALTER TABLE residents ENABLE ROW LEVEL SECURITY;
CREATE POLICY senior_resident_policy ON residents 
USING (apartment_id IN (SELECT apartment_id FROM apartments WHERE building_id = 1));
