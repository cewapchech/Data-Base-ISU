/* Вывод и совмещение высех таблиц
SELECT *
FROM `должности` d
JOIN `пользователи` u ON u.`должность_id` = d.`id`
CROSS JOIN `типы_оборудования` t
CROSS JOIN `параметры` p
CROSS JOIN `пачки` b;
*/
CREATE DATABASE IF NOT EXISTS `my_database`;
USE `my_database`;

CREATE TABLE IF NOT EXISTS `должности` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`)
);

CREATE TABLE IF NOT EXISTS `пользователи` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `имя` VARCHAR(100) NOT NULL,
    `должность_id` INTEGER NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`),
    FOREIGN KEY (`должность_id`) REFERENCES `должности` (`id`)
);

CREATE TABLE IF NOT EXISTS `типы_оборудования` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`)
);

CREATE TABLE IF NOT EXISTS `параметры` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `название` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`)
);

CREATE TABLE IF NOT EXISTS `пачки` (
    `id` INTEGER NOT NULL,
    `код` VARCHAR(20) NOT NULL,
    `количество` INTEGER NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`код`)
);

INSERT INTO `должности` (`id`, `код`, `название`)
SELECT 1, 'POS-001', 'Инженер'
WHERE NOT EXISTS (SELECT 1 FROM `должности` WHERE `код` = 'POS-001');

INSERT INTO `должности` (`id`, `код`, `название`)
SELECT 2, 'POS-002', 'Оператор'
WHERE NOT EXISTS (SELECT 1 FROM `должности` WHERE `код` = 'POS-002');

INSERT INTO `пользователи` (`id`, `код`, `имя`, `должность_id`)
SELECT 1, 'USR-001', 'Иванов Иван', 1
WHERE NOT EXISTS (SELECT 1 FROM `пользователи` WHERE `код` = 'USR-001');

INSERT INTO `пользователи` (`id`, `код`, `имя`, `должность_id`)
SELECT 2, 'USR-002', 'Петров Пётр', 2
WHERE NOT EXISTS (SELECT 1 FROM `пользователи` WHERE `код` = 'USR-002');

INSERT INTO `типы_оборудования` (`id`, `код`, `название`)
SELECT 1, 'EQ-001', 'Пресс'
WHERE NOT EXISTS (SELECT 1 FROM `типы_оборудования` WHERE `код` = 'EQ-001');

INSERT INTO `типы_оборудования` (`id`, `код`, `название`)
SELECT 2, 'EQ-002', 'Печь'
WHERE NOT EXISTS (SELECT 1 FROM `типы_оборудования` WHERE `код` = 'EQ-002');

INSERT INTO `параметры` (`id`, `код`, `название`)
SELECT 1, 'PAR-001', 'Давление'
WHERE NOT EXISTS (SELECT 1 FROM `параметры` WHERE `код` = 'PAR-001');

INSERT INTO `параметры` (`id`, `код`, `название`)
SELECT 2, 'PAR-002', 'Температура'
WHERE NOT EXISTS (SELECT 1 FROM `параметры` WHERE `код` = 'PAR-002');

INSERT INTO `пачки` (`id`, `код`, `количество`)
SELECT 1, 'BAT-001', 500
WHERE NOT EXISTS (SELECT 1 FROM `пачки` WHERE `код` = 'BAT-001');

INSERT INTO `пачки` (`id`, `код`, `количество`)
SELECT 2, 'BAT-002', 320
WHERE NOT EXISTS (SELECT 1 FROM `пачки` WHERE `код` = 'BAT-002');