-- =====================================================
-- БИЛЕТ №18
-- Сводка по месяцам, средняя сумма автостраховки,
-- количество истекших страховок, шифрование данных клиентов авто
-- =====================================================
-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE insurance_clients (
    client_id SERIAL PRIMARY KEY,-- Уникальный идентификатор клиента
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)),  -- ФИО с заглавной буквы
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$') -- Паспорт в формате 4010 123456
);

CREATE TABLE insurance_policies (
    policy_id SERIAL PRIMARY KEY, -- Уникальный идентификатор полиса
    client_id INTEGER NOT NULL REFERENCES insurance_clients(client_id), -- Клиент, которому принадлежит полис
    policy_type TEXT NOT NULL, -- Тип страховки 
    start_date DATE NOT NULL,-- Дата начала действия
    end_date DATE NOT NULL, -- Дата окончания действия 
    insurance_amount NUMERIC(12,2) NOT NULL -- Страховая сумма
);

INSERT INTO insurance_clients (full_name, phone, passport) VALUES
('Иван Петров', '812-111-0001', '4010 123456'),
('Мария Иванова', '812-111-0002', '4010 123457'),
('Петр Сидоров', '812-111-0003', '4010 123458'),
('Ольга Кузнецова', '812-111-0004', '4010 123459'),
('Сергей Смирнов', '812-111-0005', '4010 123460'),
('Анна Попова', '812-111-0006', '4010 123461'),
('Дмитрий Соколов', '812-111-0007', '4010 123462'),
('Елена Лебедева', '812-111-0008', '4010 123463'),
('Алексей Козлов', '812-111-0009', '4010 123464'),
('Татьяна Новикова', '812-111-0010', '4010 123465');

INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount) VALUES
(1, 'Автострахование', '2024-01-15', '2025-01-14', 500000),
(1, 'Квартира', '2024-01-15', '2026-01-14', 2000000),
(2, 'Автострахование', '2024-03-20', '2025-03-19', 750000),
(3, 'Автострахование', '2024-05-10', '2025-05-09', 450000),
(4, 'Квартира', '2024-07-25', '2027-07-24', 1500000),
(5, 'Автострахование', '2024-06-30', '2025-06-29', 620000),
(6, 'Автострахование', '2024-08-08', '2025-08-07', 580000),
(7, 'Квартира', '2024-09-15', '2026-09-14', 1800000),
(8, 'Автострахование', '2024-10-20', '2025-10-19', 700000),
(9, 'Автострахование', '2023-11-11', '2024-11-10', 5000000);

-- Запрос 1: Сводка по месяцам
SELECT TO_CHAR(start_date, 'YYYY-MM') AS month, policy_type, COUNT(DISTINCT client_id) AS clients_count
FROM insurance_policies
GROUP BY TO_CHAR(start_date, 'YYYY-MM'), policy_type
ORDER BY month;

-- Запрос 2: Средняя сумма автостраховки
SELECT ROUND(AVG(insurance_amount), 2) AS avg_car_insurance
FROM insurance_policies
WHERE policy_type = 'Автострахование';

-- Запрос 3: Количество истекших страховок
SELECT COUNT(*) AS expired_policies
FROM insurance_policies
WHERE end_date < CURRENT_DATE;

-- Запрос 4: Шифрование данных клиентов с автостраховкой
CREATE OR REPLACE FUNCTION encrypt_car_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(data::bytea, 'carkey12345678901234567890123456789012', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

SELECT DISTINCT c.full_name, encrypt_car_data(c.full_name) AS enc_name,
       c.phone, encrypt_car_data(c.phone) AS enc_phone,
       c.passport, encrypt_car_data(c.passport) AS enc_passport
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
WHERE p.policy_type = 'Автострахование';

