-- Справочные данные для расчета ВР и ДМК (Таблица 2, Таблица 3).

declare
    max_calc_tables integer;
    max_calc_values integer;
    max_equipment   integer;
    r               record;
begin

    -- 1. Таблицы и счетчики
    create table if not exists "справочные_таблицы_расчета" (
        id integer not null,
        "код" varchar(20) not null,
        "номер_таблицы" integer not null,
        "название" varchar(200) not null,
        "тип_оборудования_id" integer,
        "аргумент_1_тип_id" integer not null,
        "аргумент_2_тип_id" integer,
        "значение_название" varchar(100) not null,
        "значение_единица_id" integer
    );

    create table if not exists "значения_справочных_таблиц" (
        id integer not null,
        "код" varchar(20) not null,
        "таблица_id" integer not null,
        "аргумент_1" numeric(12,4) not null,
        "аргумент_2" numeric(12,4),
        "значение" numeric(12,4) not null
    );

    create sequence if not exists seq_calc_tables;
    create sequence if not exists seq_calc_values;

    alter table public."справочные_таблицы_расчета" alter column id set default nextval('public.seq_calc_tables');
    alter table public."значения_справочных_таблиц" alter column id set default nextval('public.seq_calc_values');

    alter sequence seq_calc_tables owned by public."справочные_таблицы_расчета".id;
    alter sequence seq_calc_values owned by public."значения_справочных_таблиц".id;

    -- 2. Прибор ВР как тип оборудования (ДМК уже есть в справочнике)
    insert into "типы_оборудования" (id, "код", "название")
    select 3, 'EQ-003', 'ВР (ветровое ружьё)'
    where not exists (select 1 from "типы_оборудования" t where t.id = 3);

    max_equipment := (select max(id) from public."типы_оборудования");
    perform setval('public.seq_equipment_types', max_equipment);

    -- таблицы пока пустые: счетчик настраиваем так, чтобы следующий id был max + 1
    max_calc_tables := (select coalesce(max(id), 0) from public."справочные_таблицы_расчета");
    max_calc_values := (select coalesce(max(id), 0) from public."значения_справочных_таблиц");
    perform setval('public.seq_calc_tables', max_calc_tables + 1, false);
    perform setval('public.seq_calc_values', max_calc_values + 1, false);

    -- 3. Ограничения и связи
    for r in
        select c.t, c.n, c.d
        from (values
            ('справочные_таблицы_расчета', 'pk_справочные_таблицы_расчета', 'PRIMARY KEY (id)'),
            ('справочные_таблицы_расчета', 'uq_справочные_таблицы_расчета_код', 'UNIQUE ("код")'),
            -- номер таблицы уникален внутри прибора (у общих таблиц прибор пустой)
            ('справочные_таблицы_расчета', 'uq_справочные_таблицы_номер', 'UNIQUE NULLS NOT DISTINCT ("тип_оборудования_id", "номер_таблицы")'),
            ('справочные_таблицы_расчета', 'ck_справочные_таблицы_номер', 'CHECK ("номер_таблицы" > 0)'),
            ('справочные_таблицы_расчета', 'fk_справочные_таблицы_оборудование', 'FOREIGN KEY ("тип_оборудования_id") REFERENCES "типы_оборудования" (id)'),
            ('справочные_таблицы_расчета', 'fk_справочные_таблицы_аргумент_1', 'FOREIGN KEY ("аргумент_1_тип_id") REFERENCES "типы_параметров" (id)'),
            ('справочные_таблицы_расчета', 'fk_справочные_таблицы_аргумент_2', 'FOREIGN KEY ("аргумент_2_тип_id") REFERENCES "типы_параметров" (id)'),
            ('справочные_таблицы_расчета', 'fk_справочные_таблицы_единица', 'FOREIGN KEY ("значение_единица_id") REFERENCES "единицы_измерения" (id)'),

            ('значения_справочных_таблиц', 'pk_значения_справочных_таблиц', 'PRIMARY KEY (id)'),
            ('значения_справочных_таблиц', 'uq_значения_справочных_таблиц_код', 'UNIQUE ("код")'),
            -- одна ячейка таблицы - одно значение
            ('значения_справочных_таблиц', 'uq_значения_ячейка', 'UNIQUE NULLS NOT DISTINCT ("таблица_id", "аргумент_1", "аргумент_2")'),
            ('значения_справочных_таблиц', 'fk_значения_таблица', 'FOREIGN KEY ("таблица_id") REFERENCES "справочные_таблицы_расчета" (id) ON DELETE CASCADE')
        ) as c(t, n, d)
    loop
        if not exists (select 1 from pg_constraint where conname = r.n) then
            execute format('alter table public.%I add constraint %I %s', r.t, r.n, r.d);
        end if;
    end loop;

end $$;