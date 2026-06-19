-- =====================================================
-- БИЛЕТ №19
-- Сотрудники по должности и цеху, средний возраст мужчин/женщин по цехам,
-- сотрудники с разнополыми детьми, резервная копия и восстановление
-- =====================================================

CREATE TABLE factory_shops (
    shop_id SERIAL PRIMARY KEY, -- Уникальный идентификатор цеха
    shop_name TEXT NOT NULL -- Название цеха
);

CREATE TABLE positions (
    pos_id SERIAL PRIMARY KEY, -- Уникальный идентификатор должност
    pos_name TEXT NOT NULL -- Название должности
); 

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY, -- Уникальный идентификатор сотрудника 
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)),-- ФИО с заглавной буквы
    gender CHAR(1) NOT NULL CHECK (gender IN ('М', 'Ж')),  -- Пол: только М или Ж
    birth_date DATE NOT NULL, -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    shop_id INTEGER NOT NULL REFERENCES factory_shops(shop_id), -- В каком цехе работает
    pos_id INTEGER NOT NULL REFERENCES positions(pos_id) -- Должность сотрудника
);

CREATE TABLE children (
    child_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор ребёнка
    parent_id INTEGER NOT NULL REFERENCES employees(emp_id), -- Родитель (сотрудник)
    child_name TEXT NOT NULL, -- Имя ребёнка
    child_gender CHAR(1) NOT NULL CHECK (child_gender IN ('М', 'Ж')),  -- Пол ребёнка
    child_birth_date DATE NOT NULL  -- Дата рождения ребёнка
);

INSERT INTO factory_shops (shop_name) VALUES
('Механический'),('Сборочный'),('Литейный'),('Кузнечный'),('Прессовый'),
('Инструментальный'),('Ремонтный'),('Энергоцех'),('Транспортный'),('Складской');

INSERT INTO positions (pos_name) VALUES
('Инженер'),('Технолог'),('Оператор'),('Слесарь'),('Электрик'),
('Сварщик'),('Бухгалтер'),('Экономист'),('Начальник'),('Директор');

INSERT INTO employees (full_name, gender, birth_date, phone, passport, shop_id, pos_id) VALUES
('Иван Петров', 'М', '1980-01-15', '812-111-0001', '4010 123456', 1, 1),
('Мария Иванова', 'Ж', '1985-03-20', '812-111-0002', '4010 123457', 1, 2),
('Петр Сидоров', 'М', '1975-07-25', '812-111-0003', '4010 123458', 2, 3),
('Ольга Кузнецова', 'Ж', '1990-04-22', '812-111-0004', '4010 123459', 2, 4),
('Сергей Смирнов', 'М', '1988-11-30', '812-111-0005', '4010 123460', 3, 1),
('Анна Попова', 'Ж', '1995-08-08', '812-111-0006', '4010 123461', 3, 5),
('Дмитрий Соколов', 'М', '1982-06-12', '812-111-0007', '4010 123462', 4, 3),
('Елена Лебедева', 'Ж', '1992-10-10', '812-111-0008', '4010 123463', 4, 6),
('Алексей Козлов', 'М', '1978-12-25', '812-111-0009', '4010 123464', 5, 1),
('Татьяна Новикова', 'Ж', '1983-05-18', '812-111-0010', '4010 123465', 5, 7);

INSERT INTO children (parent_id, child_name, child_gender, child_birth_date) VALUES
(1, 'Алексей', 'М', '2010-05-10'),
(1, 'Мария', 'Ж', '2012-07-15'),
(2, 'Ольга', 'Ж', '2015-03-20'),
(3, 'Дмитрий', 'М', '2008-09-15'),
(3, 'Анна', 'Ж', '2011-11-25'),
(4, 'Сергей', 'М', '2016-07-07'),
(5, 'Елена', 'Ж', '2018-08-08'),
(6, 'Павел', 'М', '2019-01-01'),
(7, 'Татьяна', 'Ж', '2017-02-02'),
(8, 'Ирина', 'Ж', '2020-03-03');

-- Запрос 1: Сотрудники по должности и цеху
SELECT e.full_name, p.pos_name, s.shop_name
FROM employees e
JOIN positions p ON e.pos_id = p.pos_id
JOIN factory_shops s ON e.shop_id = s.shop_id
WHERE p.pos_name = 'Инженер' AND s.shop_name = 'Механический';

-- Запрос 2: Средний возраст мужчин/женщин по цехам
SELECT s.shop_name,
       ROUND(AVG(CASE WHEN e.gender = 'М' THEN EXTRACT(YEAR FROM age(e.birth_date)) END), 1) AS avg_age_men,
       ROUND(AVG(CASE WHEN e.gender = 'Ж' THEN EXTRACT(YEAR FROM age(e.birth_date)) END), 1) AS avg_age_women
FROM employees e
JOIN factory_shops s ON e.shop_id = s.shop_id
GROUP BY s.shop_name;

-- Запрос 3: Сотрудники с разнополыми детьми
SELECT DISTINCT e.full_name
FROM employees e
JOIN children c1 ON e.emp_id = c1.parent_id
JOIN children c2 ON e.emp_id = c2.parent_id AND c1.child_id != c2.child_id
WHERE c1.child_gender != c2.child_gender;

-- Запрос 4 (бэкап) - в командной строке:
-- pg_dump -U postgres -F c -b -v -f "C:/backup/exam_backup.backup" имя_базы
