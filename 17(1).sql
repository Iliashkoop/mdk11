-- =====================================================
-- БИЛЕТ №17
-- Клиенты агентства «Белая башня», сводка по месяцам,
-- сумма выплат за месяц, триггер на сумму >1 млн руб.
-- =====================================================
-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE insurance_clients (
    client_id SERIAL PRIMARY KEY, -- Уникальный идентификатор клиента
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- ФИО с заглавной буквы
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    agency_name TEXT NOT NULL DEFAULT 'Стандарт'-- Название агентства (по умолчанию "Стандарт")
); 

CREATE TABLE insurance_policies ( 
    policy_id SERIAL PRIMARY KEY,-- Уникальный идентификатор полиса
    client_id INTEGER NOT NULL REFERENCES insurance_clients(client_id), -- Клиент, которому принадлежит полис
    policy_type TEXT NOT NULL, -- Тип страховки
    start_date DATE NOT NULL, -- Дата начала действия
    end_date DATE NOT NULL, -- Дата окончания действия
    insurance_amount NUMERIC(12,2) NOT NULL, -- Страховая сумма
    paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0 -- Выплаченная сумма (по умолчанию 0)
);

INSERT INTO insurance_clients (full_name, phone, passport, agency_name) VALUES
('Иван Петров', '812-111-0001', '4010 123456', 'Белая башня'),
('Мария Иванова', '812-111-0002', '4010 123457', 'Белая башня'),
('Петр Сидоров', '812-111-0003', '4010 123458', 'Стандарт'),
('Ольга Кузнецова', '812-111-0004', '4010 123459', 'Белая башня'),
('Сергей Смирнов', '812-111-0005', '4010 123460', 'Стандарт'),
('Анна Попова', '812-111-0006', '4010 123461', 'Белая башня'),
('Дмитрий Соколов', '812-111-0007', '4010 123462', 'Стандарт'),
('Елена Лебедева', '812-111-0008', '4010 123463', 'Белая башня'),
('Алексей Козлов', '812-111-0009', '4010 123464', 'Стандарт'),
('Татьяна Новикова', '812-111-0010', '4010 123465', 'Белая башня');

INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount, paid_amount) VALUES
(1, 'Авто', '2024-01-15', '2025-01-14', 500000, 500000),
(1, 'Квартира', '2024-01-15', '2026-01-14', 2000000, 200000),
(2, 'Авто', '2024-03-20', '2025-03-19', 750000, 750000),
(3, 'Авто', '2024-05-10', '2025-05-09', 450000, 450000),
(4, 'Квартира', '2024-07-25', '2027-07-24', 1500000, 150000),
(5, 'Авто', '2024-06-30', '2025-06-29', 620000, 620000),
(6, 'Авто', '2024-08-08', '2025-08-07', 580000, 580000),
(7, 'Квартира', '2024-09-15', '2026-09-14', 1800000, 180000),
(8, 'Авто', '2024-10-20', '2025-10-19', 700000, 700000),
(9, 'Жизнь', '2024-11-11', '2029-11-10', 5000000, 500000);

-- Запрос 1: Клиенты агентства «Белая башня»
SELECT full_name, phone, agency_name
FROM insurance_clients
WHERE agency_name = 'Белая башня';

-- Запрос 2: Сводка по месяцам (количество полисов по типам)
SELECT TO_CHAR(start_date, 'YYYY-MM') AS month, policy_type, COUNT(*) AS cnt
FROM insurance_policies
GROUP BY TO_CHAR(start_date, 'YYYY-MM'), policy_type
ORDER BY month;

-- Запрос 3: Сумма выплат за текущий месяц
SELECT SUM(paid_amount) AS total_paid_current_month
FROM insurance_policies
WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
  AND EXTRACT(MONTH FROM start_date) = EXTRACT(MONTH FROM CURRENT_DATE);

-- Запрос 4: Триггер на сумму > 1 млн рублей
CREATE OR REPLACE FUNCTION warn_million()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.insurance_amount > 1000000 THEN
        RAISE NOTICE 'Сумма страховки % превысила максимальный порог выплат (1 млн)', NEW.insurance_amount;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_warn_million
AFTER INSERT OR UPDATE ON insurance_policies
FOR EACH ROW EXECUTE FUNCTION warn_million();

-- 1. Вставка полиса с суммой > 1 млн (вызовет предупреждение)
INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount, paid_amount) 
VALUES (10, 'Авто', '2024-12-01', '2025-12-01', 2500000, 250000);
-- Результат: NOTICE: Внимание! Сумма страховки 2500000.00 руб. превысила максимальный порог выплат (1 млн руб.)

-- 2. Вставка полиса с суммой <= 1 млн (без предупреждения)
INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount, paid_amount) 
VALUES (10, 'Квартира', '2024-12-01', '2025-12-01', 800000, 80000);
-- Результат: без предупреждения

-- 3. Обновление полиса до суммы > 1 млн (вызовет предупреждение)
UPDATE insurance_policies SET insurance_amount = 1200000 
WHERE policy_id = 3;