-- =====================================================
-- БИЛЕТ №9
-- Бригады (первая смена), станки до указанного года, энергопотребление,
-- триггер на превышение 380 Вт
-- =====================================================

CREATE TABLE shifts (
    shift_id SERIAL PRIMARY KEY, -- Уникальный идентификатор смены
    shift_name TEXT NOT NULL -- Название смены (Первая/Вторая/Третья)
);

CREATE TABLE brigades (
    brigade_id SERIAL PRIMARY KEY, -- Уникальный идентификатор бригады
    brigade_name TEXT NOT NULL, -- Название бригады
    shift_id INTEGER NOT NULL REFERENCES shifts(shift_id)  -- В какой смене работает бригада
);

CREATE TABLE machines (
    machine_id SERIAL PRIMARY KEY, -- Уникальный идентификатор станка
    machine_name TEXT NOT NULL, -- Название станка
    power_consumption NUMERIC(10,2) NOT NULL, -- Энергопотребление в Вт
    manufacture_timestamp TIMESTAMP, -- Год выпуска станка
    brigade_id INTEGER NOT NULL REFERENCES brigades(brigade_id) -- К какой бригаде прикреплён станок
);

INSERT INTO shifts (shift_name) VALUES ('Первая смена'),('Вторая смена'),('Третья смена');

INSERT INTO brigades (brigade_name, shift_id) VALUES
('Бригада1',1),('Бригада2',1),('Бригада3',2),('Бригада4',2),('Бригада5',3),
('Бригада6',3),('Бригада7',1),('Бригада8',2),('Бригада9',3),('Бригада10',1);

INSERT INTO machines (machine_name, power_consumption, brigade_id) VALUES
INSERT INTO machines (machine_name, power_consumption, manufacture_date, brigade_id) VALUES
('Ст1', 350, '2018-01-15', 1), ('Ст2', 400, '2021-03-20', 2), ('Ст3', 300, '2019-07-10', 3),
('Ст4', 380, '2022-05-25', 4), ('Ст5', 200, '2020-11-01', 5), ('Ст6', 250, '2017-09-12', 6),
('Ст7', 500, '2023-02-28', 7), ('Ст8', 450, '2019-08-15', 8), ('Ст9', 370, '2021-12-03', 9),
('Ст10', 600, '2022-06-18', 10);

-- Запрос 1 Бригады, работающие в первую смену
SELECT b.brigade_name
FROM machines m
JOIN brigades b ON m.brigade_id = b.brigade_id
JOIN shifts s ON b.shift_id = s.shift_id
WHERE s.shift_name = 'Первая смена';

-- Запрос 2 Сравнение по году
SELECT * FROM machines 
WHERE EXTRACT(YEAR FROM manufacture_date) < 2020;

-- Запрос 3 список потребляемой электроэнергии для всех станков
SELECT machine_name, power_consumption FROM machines ORDER BY power_consumption DESC;

-- Запрос 4: Триггер для предупреждения о превышении 380 Вт
CREATE OR REPLACE FUNCTION warn_power()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.power_consumption > 380 THEN
        RAISE NOTICE 'Внимание! Станок % потребляет % Вт (превышение 380)', NEW.machine_name, NEW.power_consumption;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_warn_power
AFTER INSERT OR UPDATE ON machines
FOR EACH ROW EXECUTE FUNCTION warn_power();

-- 1. Вставка станка с мощностью > 380 (вызовет предупреждение)
INSERT INTO machines (machine_name, power_consumption, year_of_manufacture, brigade_id) 
VALUES ('Ст11', 420, 2023, 1);
-- Результат: NOTICE: Внимание! Станок Ст11 потребляет 420 Вт (превышение 380)

--- 2. Вставка станка с мощностью <= 380 (без предупреждения)
INSERT INTO machines (machine_name, power_consumption, year_of_manufacture, brigade_id) 
VALUES ('Ст12', 350, 2021, 1);
-- Результат: без предупреждения
