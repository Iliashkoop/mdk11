-- =====================================================
-- БИЛЕТ №10
-- Станки в три смены, рабочие 1 или 3 смена, суммарная энергия,
-- триггер на превышение 3500 Вт за месяц
-- =====================================================

CREATE TABLE shifts (
    shift_id SERIAL PRIMARY KEY,          -- Уникальный идентификатор смены
    shift_name TEXT NOT NULL              -- Название смены
);

CREATE TABLE brigades (
    brigade_id SERIAL PRIMARY KEY,        -- Уникальный идентификатор бригады
    brigade_name TEXT NOT NULL,           -- Название бригады
    shift_id INTEGER NOT NULL REFERENCES shifts(shift_id)       -- В какой смене работает бригада
)

CREATE TABLE machines (
    machine_id SERIAL PRIMARY KEY,        -- Уникальный идентификатор станка
    machine_name TEXT NOT NULL,           -- Название станка
    power_consumption NUMERIC(10,2) NOT NULL, -- Энергопотребление в Вт
    brigade_id INTEGER NOT NULL  REFERENCES brigades(brigade_id)   -- К какой бригаде прикреплён станок
);

-- Создаём таблицу рабочих
CREATE TABLE workers (
    worker_id SERIAL PRIMARY KEY,         -- Уникальный идентификатор рабочего
    full_name TEXT NOT NULL  CHECK (full_name = INITCAP(full_name)), -- Имя с заглавной буквы
    brigade_id INTEGER NOT NULL  REFERENCES brigades(brigade_id)   -- В какой бригаде работает
);

INSERT INTO shifts (shift_name) VALUES ('Первая смена'),('Вторая смена'),('Третья смена');

INSERT INTO brigades (brigade_name, shift_id) VALUES
('Бригада1',1),('Бригада2',1),('Бригада3',2),('Бригада4',2),('Бригада5',3),
('Бригада6',3),('Бригада7',1),('Бригада8',2),('Бригада9',3),('Бригада10',1);

INSERT INTO machines (machine_name, power_consumption, brigade_id) VALUES
('Ст1',350,1),('Ст2',400,2),('Ст3',300,3),('Ст4',380,4),('Ст5',200,5),
('Ст6',250,6),('Ст7',500,7),('Ст8',450,8),('Ст9',370,9),('Ст10',600,10);

INSERT INTO workers (full_name, brigade_id) VALUES
('Иван Петров',1),('Петр Сидоров',1),('Сергей Иванов',2),('Алексей Смирнов',3),
('Дмитрий Кузнецов',4),('Андрей Попов',5),('Владимир Соколов',6),('Михаил Лебедев',7),
('Николай Козлов',8),('Егор Новиков',9);

-- Запрос 1
SELECT DISTINCT m.machine_name
FROM machines m
JOIN brigades b ON m.brigade_id = b.brigade_id
JOIN shifts s ON b.shift_id = s.shift_id
WHERE s.shift_name = 'Третья смена';

-- Запрос 2: Рабочие 1-й и 3-й смены
SELECT w.full_name, s.shift_name
FROM workers w
JOIN brigades b ON w.brigade_id = b.brigade_id
JOIN shifts s ON b.shift_id = s.shift_id
WHERE s.shift_name IN ('Первая смена', 'Третья смена');

-- Запрос 3: Суммарное энергопотребление всех станков
SELECT SUM(power_consumption) AS total_power FROM machines;

-- Запрос 4: Триггер на превышение 3500 Вт
CREATE OR REPLACE FUNCTION check_total_power()
RETURNS TRIGGER AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT SUM(power_consumption) INTO total FROM machines;
    IF total > 3500 THEN
        RAISE EXCEPTION 'Превышение нормы! Суммарное потребление % Вт (норма 3500)', total;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_total_power
AFTER INSERT OR UPDATE ON machines
FOR EACH STATEMENT EXECUTE FUNCTION check_total_power();

-- 1. Попытка добавить станок (вызовет ошибку, т.к. 3800 > 3500)
INSERT INTO machines (machine_name, power_consumption, brigade_id) 
VALUES ('Ст11', 100, 1);
-- Результат: ERROR: Превышение нормы! Суммарное потребление 3800 Вт (норма 3500)

-- 2. Сначала удалим станок, чтобы сумма стала <= 3500
DELETE FROM machines WHERE machine_name = 'Ст10';  -- Удаляем 600 Вт
-- Теперь сумма: 3800 - 600 = 3200 Вт (<= 3500)

-- 3. Теперь можно добавить станок
INSERT INTO machines (machine_name, power_consumption, brigade_id) 
VALUES ('Ст11', 100, 1);