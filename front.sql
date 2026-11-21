USE [Front];
GO

-- 1. ЗАКУПКИ
-- 1.1 Сверка движений со справочником типов
-- RIGHT JOIN показывает и типы операций, по которым нет ни одного движения
SELECT sot.ID, sot.Description, sot.Factor,
       COUNT(so.ID) AS [строк движений]
FROM bm_StorageOperations so
RIGHT JOIN bm_StorageOperationsType sot ON sot.ID = so.OperationID
GROUP BY sot.ID, sot.Description, sot.Factor
ORDER BY sot.ID;

-- 1.2 Целостность поступлений висят ли движения без шапки и без поставщика
SELECT COUNT() AS [всего поступлений],
       SUM(CASE WHEN j.ID IS NULL THEN 1 ELSE 0 END) AS [без шапки],
       SUM(CASE WHEN so.VendorID IS NULL OR so.VendorID = 0 THEN 1 ELSE 0 END) AS [без поставщика]
FROM bm_StorageOperations so
LEFT JOIN bm_JournalBarnetDocs j ON j.ID = so.DocumentID
WHERE so.OperationID = 1;

-- 1.3 Шаг месяц группировка строкой по Period (без конвертации в datetime)
SELECT FORMAT(j.Period, 'yyyy-MM') AS [месяц],
       COUNT(DISTINCT so.DocumentID) AS [документов],
       SUM(so.Count) AS [движение],
       SUM(so.Amount) AS [сумма],
       SUM(so.TaxedAmount) AS [НДС]
FROM bm_StorageOperations so
JOIN bm_JournalBarnetDocs j ON j.ID = so.DocumentID
WHERE so.OperationID = 1
GROUP BY FORMAT(j.Period, 'yyyy-MM')
ORDER BY [месяц];

-- 1.4 Топ-5 поставщиков 2023 года с долей в общем объёме
SELECT TOP 5 v.clientid AS [поставщик],
       COUNT(DISTINCT so.DocumentID) AS [закупок],
       SUM(so.Amount) AS [сумма],
       ROUND(SUM(so.Amount)  100.0  SUM(SUM(so.Amount)) OVER (), 2) AS [доля %]
FROM bm_StorageOperations so
JOIN bm_JournalBarnetDocs j ON j.ID = so.DocumentID
JOIN vendors v ON v.id = so.VendorID
WHERE so.OperationID = 1 AND j.Period = '2023-01-01' AND j.Period  '2024-01-01'
GROUP BY v.clientid
ORDER BY [сумма] DESC;

-- 2. ПРОДАЖИ
-- 2.1 Полный спектр типов транзакций в кассовой ленте
-- видно, что 101 продажи, 501 чеки, возвратов (102) почти нет
SELECT transtype, COUNT() AS [строк], SUM(amount) AS [сумма]
FROM journal
GROUP BY transtype
ORDER BY [строк] DESC;

-- 2.2 Связь позиции с карточкой товара по артикулу (journal.id = product.productid)
SELECT COUNT() AS [позиций продаж],
       SUM(CASE WHEN p.id IS NULL THEN 1 ELSE 0 END) AS [без карточки]
FROM journal j
LEFT JOIN product p ON p.productid = j.id
WHERE j.transtype = 101;

-- 2.3 Шаг месяц через FORMAT + средний чек (NULLIF от деления на 0)
SELECT FORMAT(dater, 'yyyy-MM') AS [месяц],
       SUM(amount) AS [выручка],
       COUNT(DISTINCT receiptn) AS [чеков],
       ROUND(SUM(amount)  NULLIF(COUNT(DISTINCT receiptn), 0), 2) AS [средний чек]
FROM journal
WHERE transtype = 101
GROUP BY FORMAT(dater, 'yyyy-MM')
ORDER BY [месяц];

-- 2.4 Топ товаров по выручке. Группировка по p.id, а число разных артикулов в колонке [артикулов] подтверждает, что артикулы переиспользовались
SELECT TOP 10 p.id AS [товар], MAX(p.description) AS [название],
       COUNT(DISTINCT j.id) AS [артикулов],
       SUM(j.quantity) AS [кол-во], SUM(j.amount) AS [выручка]
FROM journal j
JOIN product p ON p.productid = j.id
WHERE j.transtype = 101
GROUP BY p.id
ORDER BY [выручка] DESC;

-- 3. ПОСТАВЩИКИ
-- 3.1 Профиль поставщика ассортимент, средняя позиция, разброс дат
SELECT v.clientid AS [поставщик],
       COUNT(DISTINCT so.ProductID) AS [товаров],
       ROUND(AVG(so.Amount), 2) AS [средняя позиция],
       SUM(so.Amount) AS [всего],
       DATEDIFF(day, MIN(j.Period), MAX(j.Period)) AS [разброс дней]
FROM bm_StorageOperations so
JOIN bm_JournalBarnetDocs j ON j.ID = so.DocumentID
JOIN vendors v ON v.id = so.VendorID
WHERE so.OperationID = 1
GROUP BY v.clientid
ORDER BY [всего] DESC;

-- 3.2 Заполненность ContractID договоры в движениях не ведутся
SELECT SUM(CASE WHEN so.ContractID IS NULL OR so.ContractID = 0 THEN 1 ELSE 0 END) AS [пустых],
       COUNT() AS [всего]
FROM bm_StorageOperations so
WHERE so.OperationID = 1;

-- 3.3 Где реально лежит наименование поставщика
SELECT SUM(CASE WHEN NULLIF(v.lastname, '') IS NULL THEN 1 ELSE 0 END) AS [пустой lastname],
       SUM(CASE WHEN NULLIF(v.clientid, '') IS NULL THEN 1 ELSE 0 END) AS [пустой clientid],
       COUNT() AS [поставщиков всего]
FROM vendors v;

-- 4. ПЕРСОНАЛ

-- 4.1 Кто продаёт выручка на логин кассира, имя подтягиваем из personnel
SELECT j.loginid, CONCAT(MAX(p.lastname), ' ', MAX(p.firstname)) AS [сотрудник],
       COUNT(DISTINCT j.receiptn) AS [чеков], SUM(j.amount) AS [выручка]
FROM journal j
LEFT JOIN personnel p ON p.personid = TRY_CAST(j.loginid AS int)
WHERE j.transtype = 101
GROUP BY j.loginid
ORDER BY [выручка] DESC;

-- 4.2 Разрез по кварталам и полугодиям (шаг по ТЗ), IIF вместо CASE
SELECT DATEPART(year, dater) AS [год],
       DATEPART(quarter, dater) AS [квартал],
       IIF(DATEPART(month, dater) = 6, 1, 2) AS [полугодие],
       COUNT(DISTINCT receiptn) AS [чеков],
       SUM(amount) AS [выручка]
FROM journal
WHERE transtype = 101
GROUP BY DATEPART(year, dater), DATEPART(quarter, dater),
         IIF(DATEPART(month, dater) = 6, 1, 2)
ORDER BY [год], [квартал];

-- 4.3 Служебный лог сессий с расшифровкой людей
SELECT TOP 10 s.PersonID, CONCAT(MAX(p.lastname), ' ', MAX(p.firstname)) AS [сотрудник],
       COUNT() AS [событий]
FROM bm_JournalSessions s
LEFT JOIN personnel p ON p.personid = s.PersonID
GROUP BY s.PersonID
ORDER BY [событий] DESC;

-- 4.4 Пустые таблицы активности персонала - одним запросом через UNION ALL
SELECT 'bm_ShiftsOperations' AS [таблица], COUNT() AS [строк] FROM bm_ShiftsOperations
UNION ALL SELECT 'bm_WorkHours', COUNT() FROM bm_WorkHours
UNION ALL SELECT 'bm_CashOperations', COUNT() FROM bm_CashOperations;

-- 5. ОСТАТКИ
-- 5.1 Готовых срезов остатков нет, считаем по движениям
SELECT 'onhand' AS [таблица], COUNT() AS [строк] FROM onhand
UNION ALL SELECT 'storagesonhand', COUNT() FROM storagesonhand
UNION ALL SELECT 'lngstock', COUNT() FROM lngstock
UNION ALL SELECT 'lngstockr', COUNT() FROM lngstockr;

-- 5.2 Накопительный остаток по товарам + счётчик минусовых движений
SELECT TOP 20 so.ProductID, MAX(pr.description) AS [товар],
       SUM(so.Count) AS [остаток],
       SUM(CASE WHEN so.Count  0 THEN 1 ELSE 0 END) AS [минусовых движений]
FROM bm_StorageOperations so
LEFT JOIN product pr ON pr.id = so.ProductID
GROUP BY so.ProductID
ORDER BY [остаток] DESC;

-- 5.3 Недельная динамика (шаг неделя) на примере товара 4348
SELECT DATEPART(year, j.Period) AS [год],
       DATEPART(iso_week, j.Period) AS [неделя],
       SUM(so.Count) AS [движение],
       SUM(SUM(so.Count)) OVER (ORDER BY DATEPART(year, j.Period),
                                        DATEPART(iso_week, j.Period)) AS [нарастающий остаток]
FROM bm_StorageOperations so
JOIN bm_JournalBarnetDocs j ON j.ID = so.DocumentID
WHERE so.ProductID = 4348
GROUP BY DATEPART(year, j.Period),
         DATEPART(iso_week, j.Period)
ORDER BY [год], [неделя];

-- 6. ABC-АНАЛИЗ
-- 6.1 Классы ABC по выручке (8095далее)
WITH sales AS (
    SELECT p.id AS ProductID, MAX(p.description) AS [товар], SUM(j.amount) AS [выручка]
    FROM journal j
    JOIN product p ON p.productid = j.id
    WHERE j.transtype = 101
    GROUP BY p.id
), ranked AS (
    SELECT ProductID, [товар], [выручка],
           SUM([выручка]) OVER (ORDER BY [выручка] DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS [нарастающая],
           SUM([выручка]) OVER () AS [итоговая]
    FROM sales
)
SELECT [товар], [выручка],
       ROUND([нарастающая]  100.0  [итоговая], 2) AS [доля нарастающая %],
       CASE WHEN [нарастающая]  100.0  [итоговая] = 80 THEN 'A'
            WHEN [нарастающая]  100.0  [итоговая] = 95 THEN 'B'
            ELSE 'C' END AS [класс]
FROM ranked
ORDER BY [выручка] DESC;

-- 6.2 Сводка сколько товаров в каждом классе и их доля выручки
WITH sales AS (
    SELECT p.id AS ProductID, SUM(j.amount) AS [выручка]
    FROM journal j
    JOIN product p ON p.productid = j.id
    WHERE j.transtype = 101
    GROUP BY p.id
), ranked AS (
    SELECT ProductID, [выручка],
           SUM([выручка]) OVER (ORDER BY [выручка] DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  100.0 
           SUM([выручка]) OVER () AS [нарастающая доля]
    FROM sales
)
SELECT CASE WHEN [нарастающая доля] = 80 THEN 'A'
            WHEN [нарастающая доля] = 95 THEN 'B'
            ELSE 'C' END AS [класс],
       COUNT() AS [товаров],
       SUM([выручка]) AS [выручка класса]
FROM ranked
GROUP BY CASE WHEN [нарастающая доля] = 80 THEN 'A'
              WHEN [нарастающая доля] = 95 THEN 'B'
              ELSE 'C' END
ORDER BY [класс];