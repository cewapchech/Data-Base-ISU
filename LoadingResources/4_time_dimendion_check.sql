-- Временное измерение (dim_time)
-- 1. Создаем последовательность для ID
CREATE SEQUENCE IF NOT EXISTS seq_dim_time;

-- 2. Создаем таблицу времени
CREATE TABLE IF NOT EXISTS dim_time (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_time'),
    time_id INT NOT NULL UNIQUE,       -- Уникальный ключ периода (YYYYMM01)
    month_start DATE NOT NULL,         -- Первый день месяца
    month_end DATE NOT NULL,           -- Последний день месяца
    month_name TEXT NOT NULL,          -- Название месяца с годом (Январь 2023)
    year INT NOT NULL,                 -- Год
    quarter_num INT NOT NULL,          -- Номер квартала (1-4)
    quarter_name TEXT NOT NULL,        -- Название квартала (1 кв 2023)
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_time IS 'Временное измерение для аналитики';

-- 3. Заполняем данными автоматически через generate_series
-- Диапазон: с января 2013 по декабрь 2026 (охватывает все возможные даты в твоей системе)
INSERT INTO dim_time (time_id, month_start, month_end, month_name, year, quarter_num, quarter_name)
SELECT DISTINCT
    EXTRACT(YEAR FROM d)::INT * 10000 + EXTRACT(MONTH FROM d)::INT * 100 + 1 AS time_id,
    DATE_TRUNC('month', d)::DATE AS month_start,
    (DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day')::DATE AS month_end,
    TO_CHAR(d, 'TMMonth YYYY') AS month_name,
    EXTRACT(YEAR FROM d)::INT AS year,
    EXTRACT(QUARTER FROM d)::INT AS quarter_num,
    EXTRACT(QUARTER FROM d)::INT || ' кв ' || EXTRACT(YEAR FROM d)::INT AS quarter_name
FROM generate_series('2013-01-01'::DATE, '2026-12-31'::DATE, INTERVAL '1 day') AS d
ORDER BY time_id;

-- 4. Проверка результатов
SELECT 
    COUNT(*) AS total_months,
    MIN(month_start) AS first_month,
    MAX(month_end) AS last_month,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM dim_time;

-- Пример первых 5 записей
SELECT * FROM dim_time ORDER BY time_id LIMIT 5;