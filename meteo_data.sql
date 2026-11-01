-- шаг 1: структура и тестовые данные метеоизмерений
do $$
declare
    max_base_units      integer;
    max_units           integer;
    max_parameter_types integer;
    max_equipment_types integer;
    max_batches         integer;
    max_parameters      integer;
    r                   record;
begin

    -- Вложенная транзакция 1
    -- Расширяем структуру: типы оборудования, время измерения пачки
    begin
        create table if not exists "типы_оборудования" (
            id integer not null,
            "код" varchar(20) not null,
            "название" varchar(100) not null
        );

        create sequence if not exists seq_equipment_types;
        alter table public."типы_оборудования" alter column id set default nextval('public.seq_equipment_types');
        alter sequence seq_equipment_types owned by public."типы_оборудования".id;

        alter table public."пачки" add column if not exists "тип_оборудования_id" integer;
        alter table public."пачки" add column if not exists "время_измерения" time;

        -- температура может быть отрицательной, поэтому запрет "значение >= 0" снимаем
        alter table public."параметры" drop constraint if exists "ck_параметры_значение";
    end;
    commit;

    -- Вложенная транзакция 2
    -- Справочники и метеоизмерения (в том числе с намеренными ошибками)
    begin
        insert into "базовые_единицы_измерения" (id, "код", "название")
        select v.id, v.k, v.n
        from (values
            (6, 'BASE-006', 'Длина'),
            (7, 'BASE-007', 'Угол')
        ) as v(id, k, n)
        where not exists (select 1 from "базовые_единицы_измерения" t where t.id = v.id);

        -- коэффициент считается относительно первой единицы категории:
        -- 1 м/с = 60 м/мин, 1 мм рт. ст. = 0,001333 бар
        insert into "единицы_измерения" (id, "код", "название", "базовая_единица_id", "коэффициент_к_базовой")
        select v.id, v.k, v.n, v.b, v.c
        from (values
            (8,  'UNIT-008', 'м',          6, 1),
            (9,  'UNIT-009', 'град',       7, 1),
            (10, 'UNIT-010', 'м/с',        3, 60),
            (11, 'UNIT-011', 'мм рт. ст.', 1, 0.001333)
        ) as v(id, k, n, b, c)
        where not exists (select 1 from "единицы_измерения" t where t.id = v.id);

        insert into "типы_параметров" (id, "код", "название", "единица_измерения_id")
        select v.id, v.k, v.n, v.u
        from (values
            (6,  'TYP-006', 'Высота метеопоста',    8),
            (7,  'TYP-007', 'Температура воздуха',  2),
            (8,  'TYP-008', 'Давление воздуха',     11),
            (9,  'TYP-009', 'Направление ветра',    9),
            (10, 'TYP-010', 'Скорость ветра',       10),
            (11, 'TYP-011', 'Дальность сноса пуль', 8)
        ) as v(id, k, n, u)
        where not exists (select 1 from "типы_параметров" t where t.id = v.id);

        insert into "типы_оборудования" (id, "код", "название")
        select v.id, v.k, v.n
        from (values
            (1, 'EQ-001', 'Метеокомплект ДМК'),
            (2, 'EQ-002', 'Метеостанция стационарная')
        ) as v(id, k, n)
        where not exists (select 1 from "типы_оборудования" t where t.id = v.id);

        -- (id, код, дата, время, сотрудник, тип оборудования)
        insert into "пачки" (id, "код", "дата_измерения", "время_измерения", "пользователь_id", "тип_оборудования_id")
        select v.id, v.k, cast(v.d as date), cast(v.tm as time), v.u, v.e
        from (values
            (10, 'BAT-010', '2026-10-05', '06:00', 1, 1),
            (11, 'BAT-011', '2026-10-05', '12:10', 2, 1),
            (12, 'BAT-012', '2026-10-06', '06:20', 3, 2),
            (13, 'BAT-013', '2026-10-07', '09:30', 1, 2),
            (14, 'BAT-014', '2026-10-07', '15:40', 2, 1),
            (15, 'BAT-015', '2026-10-08', '06:50', 3, 1),
            (16, 'BAT-016', '2026-10-09', '12:00', 1, 2),
            (17, 'BAT-017', '2026-10-10', '18:10', 2, 2),
            (18, 'BAT-018', '2026-10-11', '07:20', 3, 1)
        ) as v(id, k, d, tm, u, e)
        where not exists (select 1 from "пачки" t where t.id = v.id);

        -- (id, пачка, тип параметра, значение); по 6 параметров на пачку:
        -- 6 высота, 7 температура, 8 давление, 9 направление ветра, 10 скорость ветра, 11 снос пуль
        insert into "параметры" (id, "код", "пачка_id", "тип_параметра_id", "значение")
        select v.id, 'PAR-' || lpad(cast(v.id as varchar), 3, '0'), v.b, v.t, v.val
        from (values
            (46, 10, 6, 150),  (47, 10, 7, 12.5), (48, 10, 8, 745), (49, 10, 9, 90),  (50, 10, 10, 4),  (51, 10, 11, 12),
            (52, 11, 6, 150),  (53, 11, 7, 18),   (54, 11, 8, 752), (55, 11, 9, 180), (56, 11, 10, 6),  (57, 11, 11, 20.5),
            (58, 12, 6, 320),  (59, 12, 7, 5),    (60, 12, 8, 735), (61, 12, 9, 270), (62, 12, 10, 8),  (63, 12, 11, 30),
            -- BAT-013: температура 75 и давление 450 вне диапазона
            (64, 13, 6, 320),  (65, 13, 7, 75),   (66, 13, 8, 450), (67, 13, 9, 45),  (68, 13, 10, 3),  (69, 13, 11, 8),
            -- BAT-014: давление 880 вне диапазона
            (70, 14, 6, 150),  (71, 14, 7, 22.5), (72, 14, 8, 880), (73, 14, 9, 135), (74, 14, 10, 5),  (75, 14, 11, 15),
            -- BAT-015: направление ветра 400 вне диапазона
            (76, 15, 6, 480),  (77, 15, 7, 10),   (78, 15, 8, 720), (79, 15, 9, 400), (80, 15, 10, 12), (81, 15, 11, 40),
            -- BAT-016: скорость ветра 35 вне диапазона
            (82, 16, 6, 480),  (83, 16, 7, 0),    (84, 16, 8, 722), (85, 16, 9, 315), (86, 16, 10, 35), (87, 16, 11, 55),
            (88, 17, 6, 150),  (89, 17, 7, -20),  (90, 17, 8, 748), (91, 17, 9, 225), (92, 17, 10, 7),  (93, 17, 11, 120),
            -- BAT-018: высота метеопоста 6000 вне диапазона
            (94, 18, 6, 6000), (95, 18, 7, 30),   (96, 18, 8, 770), (97, 18, 9, 0),   (98, 18, 10, 2),  (99, 18, 11, 5)
        ) as v(id, b, t, val)
        where not exists (select 1 from "параметры" p where p.id = v.id);

        max_base_units      := (select max(id) from public."базовые_единицы_измерения");
        max_units           := (select max(id) from public."единицы_измерения");
        max_parameter_types := (select max(id) from public."типы_параметров");
        max_equipment_types := (select max(id) from public."типы_оборудования");
        max_batches         := (select max(id) from public."пачки");
        max_parameters      := (select max(id) from public."параметры");

        perform setval('public.seq_base_units', max_base_units);
        perform setval('public.seq_units', max_units);
        perform setval('public.seq_parameter_types', max_parameter_types);
        perform setval('public.seq_equipment_types', max_equipment_types);
        perform setval('public.seq_batches', max_batches);
        perform setval('public.seq_parameters', max_parameters);
    end;
    commit;

    -- Вложенная транзакция 3
    -- Ограничения и связи для новой таблицы
    begin
        for r in
            select c.t, c.n, c.d
            from (values
                ('типы_оборудования', 'pk_типы_оборудования',     'PRIMARY KEY (id)'),
                ('типы_оборудования', 'uq_типы_оборудования_код', 'UNIQUE ("код")'),
                ('пачки',             'fk_пачки_оборудование',    'FOREIGN KEY ("тип_оборудования_id") REFERENCES "типы_оборудования" (id)')
            ) as c(t, n, d)
        loop
            if not exists (select 1 from pg_constraint where conname = r.n) then
                execute format('alter table public.%I add constraint %I %s', r.t, r.n, r.d);
            end if;
        end loop;
    end;
    commit;

end $$;
