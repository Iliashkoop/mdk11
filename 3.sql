-- =====================================================
-- БИЛЕТ №3
-- Университет, работники, поиск по неполным данным, шифрование паспортов
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY, -- Уникальный идентификатор кафедры
    dept_name TEXT NOT NULL -- Название кафедры
);

CREATE TABLE workers (
    worker_id SERIAL PRIMARY KEY, -- Уникальный идентификатор работника
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- Каждое слово с заглавной буквы
    dept_id INTEGER NOT NULL REFERENCES departments(dept_id), -- Кафедра, где работает
    birth_date DATE NOT NULL, -- Дата рождения
    home_address TEXT NOT NULL, -- Домашний адрес
    work_phone TEXT CHECK (work_phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Рабочий телефон (формат: 812-111-000
    home_phone TEXT CHECK (home_phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Домашний телефон (формат: 812-222-000
    passport_data TEXT NOT NULL CHECK (passport_data ~ '^[0-9]{4} [0-9]{6}$') -- Паспортные данные (формат: 4010 123456)
);

CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY, -- Уникальный идентификатор помещения
    dept_id INTEGER NOT NULL REFERENCES departments(dept_id), -- К какой кафедре относится
    computers_count INTEGER NOT NULL DEFAULT 0 -- Количество компьютеров
);

INSERT INTO departments (dept_name) VALUES 
('ИиИТ'),('ФизФак'),('МатФак'),('ХимФак'),('БиоФак'),
('ИстФак'),('ФилФак'),('ЭкФак'),('ЮрФак'),('ПсихФак');

INSERT INTO workers (full_name, dept_id, birth_date, home_address, work_phone, home_phone, passport_data) VALUES
('Иван Петров', 1, '1980-01-01', 'ул.Ленина 1', '812-111-0001', '812-222-0001', '4010 123456'),
('Мария Сидорова', 1, '1975-02-02', 'ул.Пушкина 2', '812-111-0002', '812-222-0002', '4010 123457'),
('Алексей Смирнов', 2, '1965-03-03', 'ул.Гоголя 3', '812-111-0003', '812-222-0003', '4010 123458'),
('Ольга Кузнецова', 2, '1985-04-04', 'ул.Толстого 4', '812-111-0004', '812-222-0004', '4010 123459'),
('Дмитрий Васильев', 3, '1990-05-05', 'ул.Чехова 5', '812-111-0005', '812-222-0005', '4010 123460'),
('Елена Новикова', 3, '1970-06-06', 'ул.Достоевского 6', '812-111-0006', '812-222-0006', '4010 123461'),
('Сергей Морозов', 4, '1960-07-07', 'ул.Невская 7', '812-111-0007', '812-222-0007', '4010 123462'),
('Татьяна Волкова', 4, '1982-08-08', 'ул.Садовая 8', '812-111-0008', '812-222-0008', '4010 123463'),
('Андрей Павлов', 5, '1995-09-09', 'ул.Московская 9', '812-111-0009', '812-222-0009', '4010 123464'),
('Наталья Соколова', 5, '1978-10-10', 'ул.Колотовой 10', '812-111-0010', '812-222-0010', '4010 123465');

INSERT INTO rooms (dept_id, computers_count) VALUES
(1,25),(1,30),(2,10),(2,15),(3,20),(3,35),(4,5),(4,12),(5,40),(5,50);

-- Запрос 1: Поиск работников по неполным данным (поиск по части имени)
SELECT w.full_name, d.dept_name, w.birth_date, w.home_address, w.work_phone
FROM workers w
JOIN departments d ON w.dept_id = d.dept_id
WHERE w.full_name ILIKE '%иван%';

-- Запрос 2: Общее количество компьютеров по кафедрам
SELECT d.dept_name, SUM(r.computers_count) AS total_computers
FROM rooms r
JOIN departments d ON r.dept_id = d.dept_id
GROUP BY d.dept_name;

-- Запрос 3: Средний возраст работников
SELECT ROUND(AVG(EXTRACT(YEAR FROM age(birth_date))), 1) AS avg_age
FROM workers;

-- Запрос 4: Юбиляры (сотрудники, у которых юбилей в следующем месяце)
SELECT full_name, birth_date
FROM workers
WHERE EXTRACT(MONTH FROM birth_date) = EXTRACT(MONTH FROM CURRENT_DATE + INTERVAL '1 month')
  AND EXTRACT(YEAR FROM age(birth_date)) IN (50, 55, 60);

-- Запрос 5: Шифрование паспортных данных
CREATE OR REPLACE FUNCTION encrypt_passport(pass TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(pass::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

-- Выводим имя сотрудника и зашифрованные паспортные данные
SELECT full_name, encrypt_passport(passport_data) FROM workers;

