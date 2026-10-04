USE `my_database`;

CREATE TABLE IF NOT EXISTS `базовые_единицы_измерения` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`)
);

CREATE TABLE IF NOT EXISTS `единицы_измерения` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(20) NOT NULL,
    `базовая_единица_id` INTEGER NOT NULL,
    `коэффициент_к_базовой` DECIMAL(12,6) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`),
    FOREIGN KEY (`базовая_единица_id`) REFERENCES `базовые_единицы_измерения` (`id`)
);

CREATE TABLE IF NOT EXISTS `типы_параметров` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(100) NOT NULL,
    `единица_измерения_id` INTEGER NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`),
    FOREIGN KEY (`единица_измерения_id`) REFERENCES `единицы_измерения` (`id`)
);

INSERT INTO `базовые_единицы_измерения` (`id`, `код`, `название`)
SELECT 1, 'BASE-001', 'Давление'
WHERE NOT EXISTS (SELECT 1 FROM `базовые_единицы_измерения` WHERE `код` = 'BASE-001');

INSERT INTO `базовые_единицы_измерения` (`id`, `код`, `название`)
SELECT 2, 'BASE-002', 'Температура'
WHERE NOT EXISTS (SELECT 1 FROM `базовые_единицы_измерения` WHERE `код` = 'BASE-002');

INSERT INTO `базовые_единицы_измерения` (`id`, `код`, `название`)
SELECT 3, 'BASE-003', 'Скорость'
WHERE NOT EXISTS (SELECT 1 FROM `базовые_единицы_измерения` WHERE `код` = 'BASE-003');

INSERT INTO `единицы_измерения` (`id`, `код`, `название`, `базовая_единица_id`, `коэффициент_к_базовой`)
SELECT 1, 'UNIT-001', 'бар', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `единицы_измерения` WHERE `код` = 'UNIT-001');

INSERT INTO `единицы_измерения` (`id`, `код`, `название`, `базовая_единица_id`, `коэффициент_к_базовой`)
SELECT 2, 'UNIT-002', '°C', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM `единицы_измерения` WHERE `код` = 'UNIT-002');

INSERT INTO `единицы_измерения` (`id`, `код`, `название`, `базовая_единица_id`, `коэффициент_к_базовой`)
SELECT 3, 'UNIT-003', 'м/мин', 3, 1
WHERE NOT EXISTS (SELECT 1 FROM `единицы_измерения` WHERE `код` = 'UNIT-003');

INSERT INTO `единицы_измерения` (`id`, `код`, `название`, `базовая_единица_id`, `коэффициент_к_базовой`)
SELECT 4, 'UNIT-004', 'Па', 1, 0.00001
WHERE NOT EXISTS (SELECT 1 FROM `единицы_измерения` WHERE `код` = 'UNIT-004');

INSERT INTO `единицы_измерения` (`id`, `код`, `название`, `базовая_единица_id`, `коэффициент_к_базовой`)
SELECT 5, 'UNIT-005', 'км/ч', 3, 16.666667
WHERE NOT EXISTS (SELECT 1 FROM `единицы_измерения` WHERE `код` = 'UNIT-005');

INSERT INTO `типы_параметров` (`id`, `код`, `название`, `единица_измерения_id`)
SELECT 1, 'TYP-001', 'Давление', 1
WHERE NOT EXISTS (SELECT 1 FROM `типы_параметров` WHERE `код` = 'TYP-001');

INSERT INTO `типы_параметров` (`id`, `код`, `название`, `единица_измерения_id`)
SELECT 2, 'TYP-002', 'Температура', 2
WHERE NOT EXISTS (SELECT 1 FROM `типы_параметров` WHERE `код` = 'TYP-002');

INSERT INTO `типы_параметров` (`id`, `код`, `название`, `единица_измерения_id`)
SELECT 3, 'TYP-003', 'Скорость ленты', 3
WHERE NOT EXISTS (SELECT 1 FROM `типы_параметров` WHERE `код` = 'TYP-003');

ALTER TABLE `пачки` ADD COLUMN `дата_измерения` DATE;
ALTER TABLE `пачки` ADD COLUMN `пользователь_id` INTEGER;

UPDATE `пачки` SET `дата_измерения`= '2026-09-01', `пользователь_id` = 2 WHERE `код` = 'BAT-001';
UPDATE `пачки` SET `дата_измерения`= '2026-09-05', `пользователь_id` = 1 WHERE `код` = 'BAT-002';

ALTER TABLE `пачки` MODIFY COLUMN `дата_измерения` DATE NOT NULL;
ALTER TABLE `пачки` MODIFY COLUMN `пользователь_id` INTEGER NOT NULL;
ALTER TABLE `пачки` ADD CONSTRAINT `fk_пачки_пользователь` FOREIGN KEY (`пользователь_id`) REFERENCES `пользователи` (`id`);

ALTER TABLE `пачки` DROP COLUMN `количество`;
#правки
ALTER TABLE `параметры` ADD COLUMN `пачка_id` INTEGER;
ALTER TABLE `параметры` ADD COLUMN `тип_параметра_id` INTEGER;
ALTER TABLE `параметры` ADD COLUMN `значение` DECIMAL(10,2);

UPDATE `параметры`
SET `тип_параметра_id` = 1, `пачка_id` = 1, `значение` = 4.20
WHERE `код` = 'PAR-001';

UPDATE `параметры`
SET `тип_параметра_id` = 2, `пачка_id` = 1, `значение` = 78.50
WHERE `код` = 'PAR-002';

ALTER TABLE `параметры` MODIFY COLUMN `пачка_id` INTEGER NOT NULL;
ALTER TABLE `параметры` MODIFY COLUMN `тип_параметра_id` INTEGER NOT NULL;
ALTER TABLE `параметры` MODIFY COLUMN `значение` DECIMAL(10,2) NOT NULL;

ALTER TABLE `параметры` ADD CONSTRAINT `fk_параметры_пачка` FOREIGN KEY (`пачка_id`) REFERENCES `пачки` (`id`);
ALTER TABLE `параметры` ADD CONSTRAINT `fk_параметры_тип` FOREIGN KEY (`тип_параметра_id`) REFERENCES `типы_параметров` (`id`);

ALTER TABLE `параметры` DROP COLUMN `название`;

INSERT INTO `параметры` (`id`, `код`, `пачка_id`, `тип_параметра_id`, `значение`)
SELECT 3, 'PAR-003', 1, 3, 12.00
WHERE NOT EXISTS (SELECT 1 FROM `параметры` WHERE `код` = 'PAR-003');

INSERT INTO `параметры` (`id`, `код`, `пачка_id`, `тип_параметра_id`, `значение`)
SELECT 4, 'PAR-004', 2, 1, 3.90
WHERE NOT EXISTS (SELECT 1 FROM `параметры` WHERE `код` = 'PAR-004');

INSERT INTO `параметры` (`id`, `код`, `пачка_id`, `тип_параметра_id`, `значение`)
SELECT 5, 'PAR-005', 2, 2, 81.00
WHERE NOT EXISTS (SELECT 1 FROM `параметры` WHERE `код` = 'PAR-005');

DELETE FROM `типы_оборудования`;
DROP TABLE IF EXISTS `типы_оборудования`;

SELECT
    b.`дата_измерения`                              AS `Дата измерения`,
    b.`код`                                          AS `Номер пачки`,
    u.`имя`                                          AS `ФИО сотрудника`,
    CONCAT(tp.`название`, ' (', eu.`название`, ')')  AS `Наименование параметра и ед. измерения`,
    p.`значение`                                     AS `Значение`
FROM `параметры` p
JOIN `пачки` b              ON b.`id` = p.`пачка_id`
JOIN `пользователи` u       ON u.`id` = b.`пользователь_id`
JOIN `типы_параметров` tp   ON tp.`id` = p.`тип_параметра_id`
JOIN `единицы_измерения` eu ON eu.`id` = tp.`единица_измерения_id`
ORDER BY b.`дата_измерения`, b.`код`, tp.`название`;