-- =====================================================
-- БИЛЕТ №20
-- Сотрудники: призывники, совместители, неполный рабочий день,
-- триггер на запрет постановки на смену для призывников
-- =====================================================

CREATE TABLE factory_shops0 ( 
    shop_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор цеха
    shop_name TEXT NOT NULL -- Название цеха
);

CREATE TABLE employees0 (
    emp_id SERIAL PRIMARY KEY, -- Уникальный идентификатор сотрудника
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- ФИО с заглавной буквы
    gender CHAR(1) NOT NULL CHECK (gender IN ('М', 'Ж')), -- Пол: только М или Ж
    birth_date DATE NOT NULL,  -- Дата рождения
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    shop_id INTEGER NOT NULL REFERENCES factory_shops0(shop_id), -- В каком цехе работает
    is_conscript BOOLEAN NOT NULL DEFAULT FALSE, -- Является ли призывником
    is_part_time BOOLEAN NOT NULL DEFAULT FALSE,-- Является ли совместителем
    work_hours_per_day NUMERIC(3,1) NOT NULL DEFAULT 8.0 -- Количество рабочих часов в день
);

CREATE TABLE work_shifts0 (
    shift_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор смены
    shift_date DATE NOT NULL,  -- Дата смены
    emp_id INTEGER NOT NULL REFERENCES employees0(emp_id), -- Сотрудник на смене
    shift_hours NUMERIC(3,1) NOT NULL  -- Количество отработанных часов
);

INSERT INTO factory_shops0 (shop_name) VALUES
('Механический'),('Сборочный'),('Литейный'),('Кузнечный'),('Прессовый'),
('Инструментальный'),('Ремонтный'),('Энергоцех'),('Транспортный'),('Складской');

INSERT INTO employees0 (full_name, gender, birth_date, phone, passport, shop_id, is_conscript, is_part_time, work_hours_per_day) VALUES
('Иван Петров', 'М', '2002-01-15', '812-111-0001', '4010 123456', 1, TRUE, FALSE, 8.0),
('Мария Иванова', 'Ж', '1985-03-20', '812-111-0002', '4010 123457', 1, FALSE, FALSE, 8.0),
('Петр Сидоров', 'М', '2003-05-10', '812-111-0003', '4010 123458', 2, TRUE, FALSE, 8.0),
('Ольга Кузнецова', 'Ж', '1990-07-25', '812-111-0004', '4010 123459', 2, FALSE, TRUE, 4.0),
('Сергей Смирнов', 'М', '1985-09-15', '812-111-0005', '4010 123460', 3, FALSE, FALSE, 8.0),
('Анна Попова', 'Ж', '1992-11-30', '812-111-0006', '4010 123461', 3, FALSE, TRUE, 6.0),
('Дмитрий Соколов', 'М', '2001-02-18', '812-111-0007', '4010 123462', 4, TRUE, FALSE, 8.0),
('Елена Лебедева', 'Ж', '1988-04-22', '812-111-0008', '4010 123463', 4, FALSE, FALSE, 8.0),
('Алексей Козлов', 'М', '1995-06-12', '812-111-0009', '4010 123464', 5, FALSE, FALSE, 8.0),
('Татьяна Новикова', 'Ж', '1993-08-08', '812-111-0010', '4010 123465', 5, FALSE, TRUE, 5.0);

-- Запрос 1: Призывники
SELECT full_name, birth_date, EXTRACT(YEAR FROM age(birth_date)) AS age
FROM employees0
WHERE gender = 'М' 
  AND EXTRACT(YEAR FROM age(birth_date)) BETWEEN 18 AND 27
  AND is_conscript = TRUE;

-- Запрос 2: Совместители
SELECT full_name, work_hours_per_day
FROM employees0
WHERE is_part_time = TRUE;

-- Запрос 3: Сотрудники с неполным рабочим днём 
SELECT full_name, work_hours_per_day
FROM employees0
WHERE work_hours_per_day < 8
ORDER BY work_hours_per_day;

-- Запрос 4: Триггер на запрет постановки на смену для призывников
CREATE OR REPLACE FUNCTION prevent_conscript_shift()
RETURNS TRIGGER AS $$
DECLARE
    is_conscript_val BOOLEAN;
BEGIN
    SELECT is_conscript INTO is_conscript_val
    FROM employees0
    WHERE emp_id = NEW.emp_id;
    
    IF is_conscript_val = TRUE THEN
        RAISE EXCEPTION 'Ошибка: Сотрудник находится на военной службе (призывник). Невозможно поставить на смену.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_prevent_conscript_shift
BEFORE INSERT ON work_shifts0
FOR EACH ROW EXECUTE FUNCTION prevent_conscript_shift();
 
 -- 1. Попытка поставить на смену призывника (вызовет ошибку)
INSERT INTO work_shifts0 (shift_date, emp_id, shift_hours) 
VALUES ('2024-12-01', 1, 8.0);  -- Иван Петров - призывник
-- Результат: ERROR: Ошибка: Сотрудник Иван Петров (ID 1) находится на военной службе (призывник). Невозможно поставить на смену.

-- 2. Попытка поставить на смену призывника (Пётр Сидоров - ID 3)
INSERT INTO work_shifts0 (shift_date, emp_id, shift_hours) 
VALUES ('2024-12-01', 3, 8.0);
-- Результат: ERROR: Ошибка: Сотрудник Петр Сидоров (ID 3) находится на военной службе (призывник). Невозможно поставить на смену.

-- 3. Постановка на смену не-призывника (пройдёт успешно)
INSERT INTO work_shifts0 (shift_date, emp_id, shift_hours) 
VALUES ('2024-12-01', 2, 8.0);  -- Мария Иванова - не призывник
-- Результат: OK

-- 4. Проверка добавленных смен
SELECT * FROM work_shifts0;