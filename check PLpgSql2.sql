-- Метаданные новой структуры: таблицы, последовательности, ограничения
SELECT
    ROW_NUMBER() OVER (ORDER BY o.rang, o.name) AS "№",
    o.name AS "Наименование",
    o.type AS "Тип"
FROM (
    SELECT 1 AS rang, table_name::text AS name, 'Таблица' AS type
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'

    UNION ALL

    SELECT 2, sequence_name::text, 'Последовательность'
    FROM information_schema.sequences
    WHERE sequence_schema = 'public'

    UNION ALL

    SELECT 3, constraint_name::text,
           CASE constraint_type
               WHEN 'PRIMARY KEY' THEN 'Первичный ключ'
               WHEN 'FOREIGN KEY' THEN 'Внешний ключ'
               WHEN 'UNIQUE'      THEN 'Уникальное ограничение'
               ELSE 'Проверочное ограничение'
           END
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'public'
      AND constraint_name NOT LIKE '%_not_null'
) AS o
ORDER BY o.rang, o.name;
