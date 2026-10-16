-- Скрипт миграции PL/pgSQL
do $$
declare
    max_positions       integer;
    max_users           integer;
    max_base_units      integer;
    max_units           integer;
    max_parameter_types integer;
    max_batches         integer;
    max_parameters      integer;
    r                   record;
begin

    -- Вложенная транзакция 1
    -- Создаем таблицы и счетчики
    begin
        create table if not exists "должности" (
            id integer not null,
            "код" varchar(20) not null,
            "название" varchar(100) not null
        );

        create table if not exists "пользователи" (
            id integer not null,
            "код" varchar(20) not null,
            "имя" varchar(100) not null,
            "должность_id" integer not null
        );

        create table if not exists "базовые_единицы_измерения" (
            id integer not null,
            "код" varchar(20) not null,
            "название" varchar(100) not null
        );

        create table if not exists "единицы_измерения" (
            id integer not null,
            "код" varchar(20) not null,
            "название" varchar(20) not null,
            "базовая_единица_id" integer not null,
            "коэффициент_к_базовой" numeric(12,6) not null
        );

        create table if not exists "типы_параметров" (
            id integer not null,
            "код" varchar(20) not null,
            "название" varchar(100) not null,
            "единица_измерения_id" integer not null
        );

        create table if not exists "пачки" (
            id integer not null,
            "код" varchar(20) not null,
            "дата_измерения" date not null,
            "пользователь_id" integer not null
        );

        create table if not exists "параметры" (
            id integer not null,
            "код" varchar(20) not null,
            "пачка_id" integer not null,
            "тип_параметра_id" integer not null,
            "значение" numeric(10,2) not null
        );

        create sequence if not exists seq_positions;
        create sequence if not exists seq_users;
        create sequence if not exists seq_base_units;
        create sequence if not exists seq_units;
        create sequence if not exists seq_parameter_types;
        create sequence if not exists seq_batches;
        create sequence if not exists seq_parameters;

        alter table public."должности" alter column id set default nextval('public.seq_positions');
        alter table public."пользователи" alter column id set default nextval('public.seq_users');
        alter table public."базовые_единицы_измерения" alter column id set default nextval('public.seq_base_units');
        alter table public."единицы_измерения" alter column id set default nextval('public.seq_units');
        alter table public."типы_параметров" alter column id set default nextval('public.seq_parameter_types');
        alter table public."пачки" alter column id set default nextval('public.seq_batches');
        alter table public."параметры" alter column id set default nextval('public.seq_parameters');

        alter sequence seq_positions owned by public."должности".id;
        alter sequence seq_users owned by public."пользователи".id;
        alter sequence seq_base_units owned by public."базовые_единицы_измерения".id;
        alter sequence seq_units owned by public."единицы_измерения".id;
        alter sequence seq_parameter_types owned by public."типы_параметров".id;
        alter sequence seq_batches owned by public."пачки".id;
        alter sequence seq_parameters owned by public."параметры".id;
    end;
    commit;

    -- Вложенная транзакция 2
    -- Наполняем тестовыми данными и выравниваем счетчики
    begin
        insert into "должности" (id, "код", "название")
        select v.id, v.k, v.n
        from (values
            (1, 'POS-001', 'Инженер'),
            (2, 'POS-002', 'Оператор'),
            (3, 'POS-003', 'Начальник цеха')
        ) as v(id, k, n)
        where not exists (select 1 from "должности" t where t.id = v.id);

        insert into "пользователи" (id, "код", "имя", "должность_id")
        select v.id, v.k, v.n, v.p
        from (values
            (1, 'USR-001', 'Иванов Иван', 1),
            (2, 'USR-002', 'Петров Пётр', 2),
            (3, 'USR-003', 'Сидоров Алексей', 3)
        ) as v(id, k, n, p)
        where not exists (select 1 from "пользователи" t where t.id = v.id);

        insert into "базовые_единицы_измерения" (id, "код", "название")
        select v.id, v.k, v.n
        from (values
            (1, 'BASE-001', 'Давление'),
            (2, 'BASE-002', 'Температура'),
            (3, 'BASE-003', 'Скорость'),
            (4, 'BASE-004', 'Влажность'),
            (5, 'BASE-005', 'Вязкость')
        ) as v(id, k, n)
        where not exists (select 1 from "базовые_единицы_измерения" t where t.id = v.id);

        insert into "единицы_измерения" (id, "код", "название", "базовая_единица_id", "коэффициент_к_базовой")
        select v.id, v.k, v.n, v.b, v.c
        from (values
            (1, 'UNIT-001', 'бар',   1, 1),
            (2, 'UNIT-002', '°C',    2, 1),
            (3, 'UNIT-003', 'м/мин', 3, 1),
            (4, 'UNIT-004', 'Па',    1, 0.00001),
            (5, 'UNIT-005', 'км/ч',  3, 16.666667),
            (6, 'UNIT-006', '%',     4, 1),
            (7, 'UNIT-007', 'сП',    5, 1)
        ) as v(id, k, n, b, c)
        where not exists (select 1 from "единицы_измерения" t where t.id = v.id);

        insert into "типы_параметров" (id, "код", "название", "единица_измерения_id")
        select v.id, v.k, v.n, v.u
        from (values
            (1, 'TYP-001', 'Давление',       1),
            (2, 'TYP-002', 'Температура',    2),
            (3, 'TYP-003', 'Скорость ленты', 3),
            (4, 'TYP-004', 'Влажность',      6),
            (5, 'TYP-005', 'Вязкость',       7)
        ) as v(id, k, n, u)
        where not exists (select 1 from "типы_параметров" t where t.id = v.id);

        insert into "пачки" (id, "код", "дата_измерения", "пользователь_id")
        select v.id, v.k, cast(v.d as date), v.u
        from (values
            (1, 'BAT-001', '2026-09-01', 2),
            (2, 'BAT-002', '2026-09-05', 1),
            (3, 'BAT-003', '2026-09-08', 3),
            (4, 'BAT-004', '2026-09-10', 1),
            (5, 'BAT-005', '2026-09-12', 2),
            (6, 'BAT-006', '2026-09-14', 3),
            (7, 'BAT-007', '2026-09-16', 1),
            (8, 'BAT-008', '2026-09-18', 2),
            (9, 'BAT-009', '2026-09-20', 3)
        ) as v(id, k, d, u)
        where not exists (select 1 from "пачки" t where t.id = v.id);

        -- (id, пачка, тип параметра, значение); код PAR-xxx строится из id
        insert into "параметры" (id, "код", "пачка_id", "тип_параметра_id", "значение")
        select v.id, 'PAR-' || lpad(cast(v.id as varchar), 3, '0'), v.b, v.t, v.val
        from (values
            (1, 1, 1, 4.20),   (2, 1, 2, 78.50),  (3, 1, 3, 12.00),  (6, 1, 4, 55.00),   (7, 1, 5, 120.00),
            (4, 2, 1, 3.90),   (5, 2, 2, 81.00),  (8, 2, 3, 15.50),  (9, 2, 4, 48.00),   (10, 2, 5, 95.00),
            (11, 3, 1, 5.10),  (12, 3, 2, 65.00), (13, 3, 3, 20.00), (14, 3, 4, 60.00),  (15, 3, 5, 150.00),
            (16, 4, 1, 6.30),  (17, 4, 2, 72.50), (18, 4, 3, 18.00), (19, 4, 4, 45.00),  (20, 4, 5, 200.00),
            (21, 5, 1, 2.80),  (22, 5, 2, 90.00), (23, 5, 3, 25.00), (24, 5, 4, 70.00),  (25, 5, 5, 80.00),
            (26, 6, 1, 7.00),  (27, 6, 2, 55.00), (28, 6, 3, 30.00), (29, 6, 4, 40.00),  (30, 6, 5, 250.00),
            (31, 7, 1, 4.50),  (32, 7, 2, 100.00),(33, 7, 3, 22.00), (34, 7, 4, 58.00),  (35, 7, 5, 175.00),
            (36, 8, 1, 3.30),  (37, 8, 2, 60.00), (38, 8, 3, 10.00), (39, 8, 4, 65.00),  (40, 8, 5, 110.00),
            (41, 9, 1, 8.20),  (42, 9, 2, 110.00),(43, 9, 3, 35.00), (44, 9, 4, 50.00),  (45, 9, 5, 300.00)
        ) as v(id, b, t, val)
        where not exists (select 1 from "параметры" p where p.id = v.id);

        max_positions       := (select max(id) from public."должности");
        max_users           := (select max(id) from public."пользователи");
        max_base_units      := (select max(id) from public."базовые_единицы_измерения");
        max_units           := (select max(id) from public."единицы_измерения");
        max_parameter_types := (select max(id) from public."типы_параметров");
        max_batches         := (select max(id) from public."пачки");
        max_parameters      := (select max(id) from public."параметры");

        perform setval('public.seq_positions', max_positions);
        perform setval('public.seq_users', max_users);
        perform setval('public.seq_base_units', max_base_units);
        perform setval('public.seq_units', max_units);
        perform setval('public.seq_parameter_types', max_parameter_types);
        perform setval('public.seq_batches', max_batches);
        perform setval('public.seq_parameters', max_parameters);
    end;
    commit;

    -- Вложенная транзакция 3
    -- Подключаем ограничения и добавляем связи
    begin
        for r in
            select c.t, c.n, c.d
            from (values
                ('должности',                 'pk_должности',                 'PRIMARY KEY (id)'),
                ('пользователи',              'pk_пользователи',              'PRIMARY KEY (id)'),
                ('базовые_единицы_измерения', 'pk_базовые_единицы_измерения', 'PRIMARY KEY (id)'),
                ('единицы_измерения',         'pk_единицы_измерения',         'PRIMARY KEY (id)'),
                ('типы_параметров',           'pk_типы_параметров',           'PRIMARY KEY (id)'),
                ('пачки',                     'pk_пачки',                     'PRIMARY KEY (id)'),
                ('параметры',                 'pk_параметры',                 'PRIMARY KEY (id)'),

                ('должности',                 'uq_должности_код',                 'UNIQUE ("код")'),
                ('пользователи',              'uq_пользователи_код',              'UNIQUE ("код")'),
                ('базовые_единицы_измерения', 'uq_базовые_единицы_измерения_код', 'UNIQUE ("код")'),
                ('единицы_измерения',         'uq_единицы_измерения_код',         'UNIQUE ("код")'),
                ('типы_параметров',           'uq_типы_параметров_код',           'UNIQUE ("код")'),
                ('пачки',                     'uq_пачки_код',                     'UNIQUE ("код")'),
                ('параметры',                 'uq_параметры_код',                 'UNIQUE ("код")'),

                ('пользователи',      'fk_пользователи_должность',  'FOREIGN KEY ("должность_id") REFERENCES "должности" (id)'),
                ('единицы_измерения', 'fk_единицы_базовая',         'FOREIGN KEY ("базовая_единица_id") REFERENCES "базовые_единицы_измерения" (id)'),
                ('типы_параметров',   'fk_типы_параметров_единица', 'FOREIGN KEY ("единица_измерения_id") REFERENCES "единицы_измерения" (id)'),
                ('пачки',             'fk_пачки_пользователь',      'FOREIGN KEY ("пользователь_id") REFERENCES "пользователи" (id)'),
                ('параметры',         'fk_параметры_пачка',         'FOREIGN KEY ("пачка_id") REFERENCES "пачки" (id)'),
                ('параметры',         'fk_параметры_тип',           'FOREIGN KEY ("тип_параметра_id") REFERENCES "типы_параметров" (id)'),

                ('единицы_измерения', 'ck_единицы_коэффициент', 'CHECK ("коэффициент_к_базовой" > 0)'),
                ('параметры',         'ck_параметры_значение',  'CHECK ("значение" >= 0)')
            ) as c(t, n, d)
        loop
            if not exists (select 1 from pg_constraint where conname = r.n) then
                execute format('alter table public.%I add constraint %I %s', r.t, r.n, r.d);
            end if;
        end loop;
    end;
    commit;

    -- Вложенная транзакция 4
    -- Добавляем рассчетную таблицу (Расчет температуры, таблица 1 для след работ)
    begin
        create table if not exists "расчет_температуры_таблица_1" (
            "температура" numeric(8,2) not null primary key,
            "поправка"    numeric(8,2) not null
        );

        insert into "расчет_температуры_таблица_1" ("температура", "поправка")
        select v.t, v.c
        from (values
            (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5)
        ) as v(t, c)
        where not exists (select 1 from "расчет_температуры_таблица_1" x where x."температура" = v.t);
    end;
    commit;

end $$;
