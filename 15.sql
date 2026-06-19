-- =====================================================
-- БИЛЕТ №15
-- Страховая компания: клиенты с автостраховкой, в текущем месяце,
-- на заданное количество лет, шифрование ФИО, телефона, паспорта
-- =====================================================
-- Подключаем расширение для криптографии
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE insurance_clients (
    client_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор клиента
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)), -- ФИО с заглавной буквы
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'), -- Телефон в формате 812-111-0001
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'), -- Паспорт в формате 4010 123456
    address TEXT NOT NULL -- Адрес проживания
);

CREATE TABLE insurance_policies (
    policy_id SERIAL PRIMARY KEY, -- Уникальный идентификатор полиса 
    client_id INTEGER NOT NULL REFERENCES insurance_clients(client_id), -- Клиент, которому принадлежит полис
    policy_type TEXT NOT NULL CHECK (policy_type IN ('Автострахование', 'Страхование квартиры', 'Страхование жизни', 'Страхование здоровья')),  -- Тип страховки
    start_date DATE NOT NULL, -- Дата начала действия полиса
    end_date DATE NOT NULL,-- Дата окончания действия полиса
    insurance_amount NUMERIC(12,2) NOT NULL -- Страховая сумма
);

INSERT INTO insurance_clients (full_name, phone, passport, address) VALUES
('Иван Петров', '812-111-0001', '4010 123456', 'Москва, ул.Ленина 1'),
('Мария Иванова', '812-111-0002', '4010 123457', 'СПб, Невский 10'),
('Петр Сидоров', '812-111-0003', '4010 123458', 'Новосибирск, Советская 5'),
('Ольга Кузнецова', '812-111-0004', '4010 123459', 'Екатеринбург, Ленина 15'),
('Сергей Смирнов', '812-111-0005', '4010 123460', 'Казань, Баумана 20'),
('Анна Попова', '812-111-0006', '4010 123461', 'Нижний Новгород, Покровская 8'),
('Дмитрий Соколов', '812-111-0007', '4010 123462', 'Челябинск, Кирова 12'),
('Елена Лебедева', '812-111-0008', '4010 123463', 'Омск, Ленина 30'),
('Алексей Козлов', '812-111-0009', '4010 123464', 'Самара, Куйбышева 7'),
('Татьяна Новикова', '812-111-0010', '4010 123465', 'Ростов, Садовая 3');

INSERT INTO insurance_policies (client_id, policy_type, start_date, end_date, insurance_amount) VALUES
(1, 'Автострахование', '2024-01-15', '2025-01-14', 500000),
(1, 'Страхование квартиры', '2024-01-15', '2026-01-14', 2000000),
(2, 'Автострахование', '2024-03-20', '2025-03-19', 750000),
(3, 'Автострахование', '2024-05-10', '2025-05-09', 450000),
(4, 'Страхование квартиры', '2024-07-25', '2027-07-24', 1500000),
(5, 'Автострахование', '2024-06-30', '2025-06-29', 620000),
(6, 'Автострахование', '2024-08-08', '2025-08-07', 580000),
(7, 'Страхование квартиры', '2024-09-15', '2026-09-14', 1800000),
(8, 'Автострахование', '2024-10-20', '2025-10-19', 700000),
(9, 'Страхование жизни', '2024-11-11', '2029-11-10', 5000000);

-- Запрос 1: Клиенты с автострахованием
SELECT c.full_name, c.phone, p.start_date, p.insurance_amount
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
WHERE p.policy_type = 'Автострахование';

-- Запрос 2: Полисы, начавшиеся в текущем месяце
SELECT c.full_name, p.policy_type, p.start_date
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
WHERE EXTRACT(YEAR FROM p.start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
  AND EXTRACT(MONTH FROM p.start_date) = EXTRACT(MONTH FROM CURRENT_DATE);

-- Запрос 3: Страхование квартиры на 2+ лет
SELECT c.full_name, p.start_date, p.end_date
FROM insurance_clients c
JOIN insurance_policies p ON c.client_id = p.client_id
WHERE p.policy_type = 'Страхование квартиры'
  AND EXTRACT(YEAR FROM age(p.end_date, p.start_date)) >= 2;

-- Запрос 4: Шифрование ФИО, телефона и паспорта
CREATE OR REPLACE FUNCTION encrypt_client_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(data::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

SELECT full_name, encrypt_client_data(full_name) AS enc_name,
       phone, encrypt_client_data(phone) AS enc_phone,
       passport, encrypt_client_data(passport) AS enc_passport
FROM insurance_clients;


