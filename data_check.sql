SELECT
    u.имя            AS "Сотрудник",
    COUNT(p.id)      AS "Количество_измерений"
FROM пользователи u
LEFT JOIN пачки b     ON b.пользователь_id = u.id
LEFT JOIN параметры p ON p.пачка_id = b.id
GROUP BY u.id, u.имя
ORDER BY u.имя;

SELECT
    b.код AS "Пачка_без_измерений"
FROM пачки b
LEFT JOIN параметры p ON p.пачка_id = b.id
WHERE p.id IS NULL;

SELECT
    b.код          AS "Номер_пачки",
    COUNT(p.id)    AS "Количество_параметров"
FROM пачки b
LEFT JOIN параметры p ON p.пачка_id = b.id
GROUP BY b.id, b.код
ORDER BY b.код;

SELECT
    p.код         AS "Измерение",
    tp.название   AS "Параметр",
    p.значение    AS "Значение_вне_диапазона"
FROM параметры p
JOIN типы_параметров tp ON tp.id = p.тип_параметра_id
WHERE
    (tp.код = 'TYP-001' AND (p.значение < 1  OR p.значение > 10))  OR
    (tp.код = 'TYP-002' AND (p.значение < 20 OR p.значение > 150)) OR
    (tp.код = 'TYP-003' AND (p.значение < 5  OR p.значение > 50))  OR
    (tp.код = 'TYP-004' AND (p.значение < 0  OR p.значение > 100)) OR
    (tp.код = 'TYP-005' AND (p.значение < 10 OR p.значение > 500));

SELECT
    tp.код        AS "Тип_параметра",
    tp.название   AS "Наименование",
    be.название   AS "Фактическая_базовая_величина"
FROM типы_параметров tp
JOIN единицы_измерения eu         ON eu.id = tp.единица_измерения_id
JOIN базовые_единицы_измерения be ON be.id = eu.базовая_единица_id
WHERE
    (tp.код = 'TYP-001' AND be.код <> 'BASE-001') OR
    (tp.код = 'TYP-002' AND be.код <> 'BASE-002') OR
    (tp.код = 'TYP-003' AND be.код <> 'BASE-003') OR
    (tp.код = 'TYP-004' AND be.код <> 'BASE-004') OR
    (tp.код = 'TYP-005' AND be.код <> 'BASE-005');