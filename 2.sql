-- =====================================================
-- БИЛЕТ №2
-- Университет, кафедры, помещения, триггер на название кафедры
-- =====================================================

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY, -- Уникальный идентификатор кафедры
    dept_name TEXT NOT NULL UNIQUE -- Название кафедры (обязательное, уникальное)
);

CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор помещения
    room_number TEXT NOT NULL, -- Номер аудитории (например, "101")
    dept_id INTEGER NOT NULL REFERENCES departments(dept_id), -- К какой кафедре относится помещение
    area NUMERIC(8,2) NOT NULL, -- Площадь в кв. метрах (с 2 знаками после запятой)
    computers_count INTEGER NOT NULL DEFAULT 0, -- Количество компьютеров (по умолчанию 0)
    repair_year INTEGER, -- Год последнего ремонта (может быть NULL)
    phone TEXT CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$') -- Телефон в формате 812-111-0001 (может быть NULL)
);

INSERT INTO departments (dept_name) VALUES 
('Кафедра Информатики'),('Кафедра Физики'),('Кафедра Математики'),('Кафедра Химии'),('Кафедра Биологии'),
('Кафедра Истории'),('Кафедра Философии'),('Кафедра Экономики'),('Кафедра Языков'),('Кафедра Спорта');

INSERT INTO rooms (room_number, dept_id, area, computers_count, repair_year, phone) VALUES
('101',1,50,25,2026,'812-111-0001'),('102',1,60,30,2025,'812-111-0002'),
('201',2,40,10,2026,'812-111-0003'),('202',2,55,15,2024,'812-111-0004'),
('301',3,45,20,2026,'812-111-0005'),('302',3,70,35,2023,'812-111-0006'),
('401',4,35,5,2026,'812-111-0007'),('402',4,65,12,2025,'812-111-0008'),
('501',5,80,40,2026,'812-111-0009'),('502',5,90,50,2022,'812-111-0010'),
('601',6,30,0,2026,'812-111-0011'),('602',6,25,0,2026,'812-111-0012'),
('701',7,100,0,2026,'812-111-0013'),('801',8,42,18,2026,'812-111-0014'),
('901',9,38,8,2024,'812-111-0015'),('1001',10,50,0,2026,'812-111-0016');

-- Запрос 1: Общее количество компьютеров по кафедрам
SELECT d.dept_name, SUM(r.computers_count) AS total_computers
FROM rooms r
JOIN departments d ON r.dept_id = d.dept_id
GROUP BY d.dept_name;

-- Запрос 2: Средняя площадь помещений кафедры Информатики
SELECT d.dept_name, ROUND(AVG(r.area), 2) AS avg_area
FROM rooms r
JOIN departments d ON r.dept_id = d.dept_id
WHERE d.dept_name = 'Кафедра Информатики'
GROUP BY d.dept_name;

-- Запрос 3: Помещения, отремонтированные в 2026 году
SELECT r.room_number, d.dept_name, r.repair_year
FROM rooms r
JOIN departments d ON r.dept_id = d.dept_id
WHERE r.repair_year = 2026;

-- Запрос 4: Триггер для проверки длины названия кафедры
CREATE OR REPLACE FUNCTION check_dept_name()
RETURNS TRIGGER AS $$
BEGIN
    IF LENGTH(NEW.dept_name) < 5 THEN
        RAISE EXCEPTION 'Название кафедры слишком короткое';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаём триггер, который срабатывает ДО вставки или обновления записи
CREATE TRIGGER tr_check_dept_name
BEFORE INSERT OR UPDATE ON departments
FOR EACH ROW EXECUTE FUNCTION check_dept_name();

-- Эта вставка вызовет ошибку, т.к. название слишком короткое:
-- INSERT INTO departments (dept_name) VALUES ('Кф');  -- ERROR: Название кафедры слишком короткое

-- А эта вставка пройдёт успешно (название длиннее 5 символов):
-- INSERT INTO departments (dept_name) VALUES ('Кафедра Робототехники');
