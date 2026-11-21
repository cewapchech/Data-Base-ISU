-- CREATE DATABASE IF NOT EXISTS db_olap_analytics;

-- 1. ЕДИНИЦЫ ИЗМЕРЕНИЯ (dim_ranges)
CREATE SEQUENCE IF NOT EXISTS seq_dim_ranges;

CREATE TABLE IF NOT EXISTS dim_ranges (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_ranges'),
    external_id BIGINT,
    name TEXT,
    factor FLOAT,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_ranges IS 'Единицы измерения ресурсов';
COMMENT ON COLUMN dim_ranges.id IS 'Внутренний ключ';
COMMENT ON COLUMN dim_ranges.external_id IS 'ID из исходной системы';
COMMENT ON COLUMN dim_ranges.name IS 'Наименование единицы измерения';
COMMENT ON COLUMN dim_ranges.factor IS 'Коэффициент пересчета';

-- 2. КАТЕГОРИИ ТОВАРОВ (dim_categories)
CREATE SEQUENCE IF NOT EXISTS seq_dim_categories;

CREATE TABLE IF NOT EXISTS dim_categories (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_categories'),
    external_id BIGINT,
    name TEXT,
    parent_id BIGINT,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_categories IS 'Категории товаров (иерархическая структура)';
COMMENT ON COLUMN dim_categories.parent_id IS 'ID родительской категории (NULL для корневых)';

-- 3. ПОСТАВЩИКИ (dim_vendors)
CREATE SEQUENCE IF NOT EXISTS seq_dim_vendors;

CREATE TABLE IF NOT EXISTS dim_vendors (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_vendors'),
    external_id BIGINT,
    name TEXT,
    parent_id BIGINT,
    parent_name TEXT,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_vendors IS 'Поставщики с группировкой';

-- 4. ТОВАРЫ/ПРОДУКЦИЯ (dim_products)
CREATE SEQUENCE IF NOT EXISTS seq_dim_products;

CREATE TABLE IF NOT EXISTS dim_products (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_products'),
    external_id BIGINT,
    name TEXT,
    category_id BIGINT REFERENCES dim_categories(id),
    vendor_id BIGINT REFERENCES dim_vendors(id),
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_products IS 'Справочник товаров';

-- 5. ПЕРСОНАЛ (dim_personnel)
CREATE SEQUENCE IF NOT EXISTS seq_dim_personnel;

CREATE TABLE IF NOT EXISTS dim_personnel (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_personnel'),
    external_id BIGINT,
    last_name TEXT,
    first_name TEXT,
    middle_name TEXT,
    role INT,
    is_technical BOOLEAN DEFAULT FALSE,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_personnel IS 'Сотрудники компании';

-- 6. СКЛАДЫ (dim_storages)
CREATE SEQUENCE IF NOT EXISTS seq_dim_storages;

CREATE TABLE IF NOT EXISTS dim_storages (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_storages'),
    external_id BIGINT,
    name TEXT,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_storages IS 'Складские помещения';

-- 7. ТИПЫ ОПЕРАЦИЙ (dim_operation_types)
CREATE SEQUENCE IF NOT EXISTS seq_dim_operation_types;

CREATE TABLE IF NOT EXISTS dim_operation_types (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_operation_types'),
    external_id BIGINT,
    name TEXT,
    factor INT,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_operation_types IS 'Типы складских операций (приход/расход)';
COMMENT ON COLUMN dim_operation_types.factor IS 'Знак операции (+1 приход, -1 расход)';

-- 8. ВРЕМЯ (dim_time)
CREATE SEQUENCE IF NOT EXISTS seq_dim_time;

CREATE TABLE IF NOT EXISTS dim_time (
    id BIGINT PRIMARY KEY DEFAULT nextval('public.seq_dim_time'),
    time_id INT NOT NULL UNIQUE,
    month_start DATE NOT NULL,
    month_end DATE NOT NULL,
    month_name TEXT NOT NULL,
    year INT NOT NULL,
    quarter_num INT NOT NULL,
    quarter_name TEXT NOT NULL,
    date_add TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE dim_time IS 'Временное измерение для аналитики';

-- ИНДЕКСЫ для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_dim_products_category ON dim_products(category_id);
CREATE INDEX IF NOT EXISTS idx_dim_products_vendor ON dim_products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_dim_categories_parent ON dim_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_dim_time_year ON dim_time(year);
CREATE INDEX IF NOT EXISTS idx_dim_time_quarter ON dim_time(quarter_num);
