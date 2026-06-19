CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE shops (
    shop_id SERIAL PRIMARY KEY,
    shop_name TEXT NOT NULL
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL CHECK (full_name = INITCAP(full_name)),
    birth_date DATE NOT NULL,
    gender CHAR(1) NOT NULL CHECK (gender IN ('М', 'Ж')),
    salary NUMERIC(10,2) NOT NULL,
    shop_id INTEGER NOT NULL REFERENCES shops(shop_id),
    phone TEXT NOT NULL CHECK (phone ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),
    passport TEXT NOT NULL CHECK (passport ~ '^[0-9]{4} [0-9]{6}$'),
    salary_account TEXT
);

INSERT INTO shops (shop_name) VALUES 
('Цех1'),('Цех2'),('Цех3'),('Цех4'),('Цех5'),
('Цех6'),('Цех7'),('Цех8'),('Цех9'),('Цех10');

INSERT INTO employees (full_name, birth_date, gender, salary, shop_id, phone, passport, salary_account) VALUES
('Иван Петров', '1960-01-15', 'М', 50000, 1, '812-123-4567', '4010 123456', 'acc1'),
('Петр Сидоров', '1970-05-20', 'М', 60000, 1, '812-123-4568', '4010 123457', 'acc2'),
('Анна Смирнова', '1968-07-25', 'Ж', 52000, 2, '812-123-4569', '4010 123458', 'acc3'),
('Елена Кузнецова', '1955-09-30', 'Ж', 48000, 2, '812-123-4570', '4010 123459', 'acc4'),
('Ольга Васильева', '2000-01-15', 'Ж', 45000, 3, '812-123-4571', '4010 123460', 'acc5'),
('Дмитрий Новиков', '1985-12-10', 'М', 70000, 3, '812-123-4572', '4010 123461', 'acc6'),
('Мария Федорова', '1990-11-20', 'Ж', 65000, 4, '812-123-4573', '4010 123462', 'acc7'),
('Алексей Морозов', '1965-04-25', 'М', 72000, 4, '812-123-4574', '4010 123463', 'acc8'),
('Татьяна Волкова', '2001-06-30', 'Ж', 43000, 5, '812-123-4575', '4010 123464', 'acc9'),
('Николай Зайцев', '1958-02-17', 'М', 51000, 5, '812-123-4576', '4010 123465', 'acc10');

-- Запрос 1: пенсионеры
SELECT COUNT(*) AS pensioners_count
FROM employees
WHERE (gender = 'Ж' AND EXTRACT(YEAR FROM age(birth_date)) >= 55)
   OR (gender = 'М' AND EXTRACT(YEAR FROM age(birth_date)) >= 60);

-- Запрос 2: средняя зарплата по цехам
SELECT s.shop_name, ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN shops s ON e.shop_id = s.shop_id
GROUP BY s.shop_name;

-- Запрос 3: сумма выплат по цехам
SELECT s.shop_name, SUM(e.salary) AS total_salary
FROM employees e
JOIN shops s ON e.shop_id = s.shop_id
GROUP BY s.shop_name;

-- Запрос 4: шифрование счета
CREATE OR REPLACE FUNCTION encrypt_account(acc TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(encrypt(acc::bytea, '1234567890123456', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

SELECT full_name, encrypt_account(salary_account) FROM employees;
