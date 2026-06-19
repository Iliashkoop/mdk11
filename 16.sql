-- =====================================================
-- БИЛЕТ №16
-- Клиенты, прервавшие выплаты досрочно, 2 и более страховок,
-- удаление с истекшим сроком, UUID для договоров
-- =====================================================
-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Подключаем расширение для генерации UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE insurance_clients (
    client_id SERIAL PRIMARY KEY, -- Уникальный идентификатор клиента
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- ФИО с заглавной буквы
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$') -- Паспорт в формате 4010 123456
);

CREATE TABLE insurance_policies (
    policy_id SERIAL PRIMARY KEY, -- Уникальный идентификатор полиса
    client_id INTEGER NOT NULL REFERENCES insurance_clients(client_id),  -- Клиент, которому принадлежит полис
    policy_type TEXT NOT NULL,  -- Тип страховки
    start_date DATE NOT NULL, -- Дата начала действия
    end_date DATE NOT NULL, -- Дата окончания действия
    insurance_amount NUMERIC(12,2) NOT NULL, -- Страховая сумма
    is_terminated_early BOOLEAN NOT NULL DEFAULT FALSE, -- Прерван ли досрочно
    termination_date DATE, -- Дата расторжения
    policy_uuid UUID DEFAULT uuid_generate_v4() -- Уникальный UUID договора
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

INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount, is_terminated_early, termination_date) VALUES
(1, 'Авто', '2024-01-15', '2025-01-14', 500000, TRUE, '2024-08-01'),
(1, 'Квартира', '2024-01-15', '2026-01-14', 2000000, FALSE, NULL),
(2, 'Авто', '2024-03-20', '2025-03-19', 750000, FALSE, NULL),
(2, 'Жизнь', '2024-03-20', '2029-03-19', 3000000, FALSE, NULL),
(3, 'Авто', '2024-05-10', '2025-05-09', 450000, TRUE, '2024-09-15'),
(4, 'Квартира', '2024-07-25', '2027-07-24', 1500000, FALSE, NULL),
(5, 'Авто', '2024-06-30', '2025-06-29', 620000, FALSE, NULL),
(5, 'Здоровье', '2024-06-30', '2025-06-29', 1000000, FALSE, NULL),
(6, 'Авто', '2024-08-08', '2025-08-07', 580000, FALSE, NULL),
(7, 'Квартира', '2024-09-15', '2026-09-14', 1800000, FALSE, NULL);

-- Запрос 1: Клиенты, прервавшие выплаты досрочно
SELECT c.full_name, p.policy_type, p.termination_date
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
WHERE p.is_terminated_early = TRUE;

-- Запрос 2: Клиенты с 2 и более страховками
SELECT c.full_name, COUNT(*) AS policies_count
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
GROUP BY c.client_id, c.full_name
HAVING COUNT(*) >= 2;

-- Запрос 3: Удаление полисов с истекшим сроком
DELETE FROM insurance_policies
WHERE end_date < CURRENT_DATE AND is_terminated_early = FALSE;

-- Запрос 4: Просмотр UUID договоров
SELECT policy_id, policy_uuid FROM insurance_policies;
