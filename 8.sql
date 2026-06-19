-- =====================================================
-- БИЛЕТ №8
-- Станки: типы станков, характеристики, энергопотребление
-- =====================================================

CREATE TABLE machine_types (
    type_id SERIAL PRIMARY KEY, -- Уникальный идентификатор типа
    type_name TEXT NOT NULL); -- Название типа станка

CREATE TABLE machines (
    machine_id SERIAL PRIMARY KEY, -- Уникальный идентификатор станка
    machine_name TEXT NOT NULL, -- Название станка
    type_id INTEGER NOT NULL REFERENCES machine_types(type_id), -- Тип станка (внешний ключ)
    price NUMERIC(12,2) NOT NULL, -- Цена станка (с 2 знаками после запятой)
    power_consumption NUMERIC(10,2) NOT NULL, -- Энергопотребление в кВт·ч
    workers_count INTEGER NOT NULL DEFAULT 1); -- Количество обслуживающих рабочих (по умолчанию 1)

INSERT INTO machine_types (type_name) VALUES 
('Токарный'),('Фрезерный'),('Сверлильный'),('Шлифовальный'),('Расточной'),
('Строгальный'),('Зуборезный'),('Резьбонарезной'),('Электроэрозионный'),('Лазерный');

INSERT INTO machines (machine_name, type_id, price, power_consumption, workers_count) VALUES
('Станок1', 1, 150000, 5000, 1),('Станок2', 1, 180000, 5500, 2),('Станок3', 2, 120000, 6000, 1),
('Станок4', 2, 220000, 7000, 2),('Станок5', 3, 95000, 3000, 1),('Станок6', 3, 110000, 3500, 1),
('Станок7', 4, 200000, 4000, 1),('Станок8', 4, 250000, 4500, 2),('Станок9', 5, 300000, 8000, 2),
('Станок10', 6, 175000, 6500, 1);

-- Запрос 1: Станки в ценовом диапазоне от 100 000 до 200 000
SELECT machine_name, price
FROM machines
WHERE price BETWEEN 100000 AND 200000;

-- Запрос 2: Только токарные станки с их ценами
SELECT m.machine_name, m.price, mt.type_name
FROM machines m
JOIN machine_types mt ON m.type_id = mt.type_id
WHERE mt.type_name = 'Токарный';

-- Запрос 3: Энергопотребление на одного рабочего
SELECT machine_name, ROUND(power_consumption / workers_count, 2) AS power_per_worker
FROM machines;

-- Запрос 4 (бэкап) - в командной строке
	-- pg_dump -U postgres -F c -b -v -f "C:/backup/exam_backup.backup" имя_базы
