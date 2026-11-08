-- Расчетные таблицы корректировок (Таблица 2, Таблица 3) для ВР и ДМК.

do $$
declare
    r       record;
    var_bad integer;
begin

    -- БЛОК 1. УЧЕБНЫЙ СКРИПТ 20261102.sql
    -- Создаем новые структуры
    begin

        -- Таблица стандартных высот
        create sequence if not exists calc_correction_height_seq;
        create table if not exists calc_correction_heights
        (
            id integer primary key not null default nextval('public.calc_correction_height_seq'),
            height integer not null
        );

        insert into calc_correction_heights(height)
        select v.h
        from (values (200), (400), (800), (1200), (1600), (2000), (2400), (3000), (4000)) as v(h)
        where not exists (select 1 from calc_correction_heights t where t.height = v.h)
        order by v.h;

        comment on table calc_correction_heights is 'Таблица стандартных высот';
        comment on column calc_correction_heights.id is 'Уникальный код';
        comment on column calc_correction_heights.height is 'Высота';

        -- Справочник типов таблиц корректировок
        create sequence if not exists calc_correction_types_seq;
        create table if not exists calc_correction_types
        (
            id integer not null primary key default nextval('public.calc_correction_types_seq'),
            parent_id integer,
            measurment_equipment_id integer,
            description text not null,
            header_values integer[]
        );

        comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
        comment on column calc_correction_types.id is 'Уникальный код';
        comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
        comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
        comment on column calc_correction_types.description is 'Описание к таблице';
        comment on column calc_correction_types.header_values is 'Значения в заголовке таблице';

        -- Универсальная таблица корректировок
        create sequence if not exists calc_correction_seq;
        create table if not exists calc_correction
        (
            id integer not null primary key default nextval('public.calc_correction_seq'),
            height_id integer not null,
            type_id integer not null,
            row_values integer[]
        );

        comment on table calc_correction is 'Универсальная таблица корректировок';
        comment on column calc_correction.id is 'Уникальный код';
        comment on column calc_correction.height_id is 'Код высоты';
        comment on column calc_correction.type_id is 'Код типа таблиц';
        comment on column calc_correction.row_values is 'Значения с корректировками';

    end;
    commit;

    -- Добавляем данные (АДАПТАЦИЯ: только если справочники еще пусты)
    begin

        if not exists (select 1 from public.calc_correction_types) then

            insert into calc_correction_types(description, header_values)
            values ('Таблица 2', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 10, 20, 30, 40, 50]),  -- 1
                   ('Таблица 3, скорость среднего ветра', null),                            -- 2
                   ('Таблица 3, направление среднего ветра', null);                         -- 3

            insert into calc_correction_types(description, parent_id, measurment_equipment_id, header_values)
            values
            ('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),      -- 4
            ('Таблица 3, Направление среднего ветра (ВР)', 3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),   -- 5
            ('Таблица 3, Скорость среднего ветра (ДМК)', 2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),              -- 6
            ('Таблица 3, Направление среднего ветра (ДМК)', 3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);           -- 7

            insert into calc_correction_types(description, parent_id)
            values ('Таблица 2, Положительные температуры', 1),   -- 8
                   ('Таблица 2, Отрицательные температуры', 1);   -- 9

        end if;

        if not exists (select 1 from public.calc_correction) then

            insert into calc_correction(height_id, type_id, row_values)
            -- Таблица 2, отрицательные значения
            values (1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]),  -- 200
                   (2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]),  -- 400
                   (3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]),  -- 800
                   (4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]),  -- 1200
            -- Таблица 2, положительные значения
                   (1, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),  -- 200
                   (2, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),  -- 400
                   (3, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),  -- 800
                   (4, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),  -- 1200
            -- Таблица 3, Скорость среднего ветра (ВР)
                   (1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]),    -- 200
                   (2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),  -- 400
                   (3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]),  -- 800
                   (4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]),  -- 1200
            -- Таблица 3, Направление среднего ветра (ВР)
                   (1, 5, array[0]),  -- 200
                   (2, 5, array[1]),  -- 400
                   (3, 5, array[2]),  -- 800
                   (4, 5, array[2]),  -- 1200
            -- Таблица 3, Скорость среднего ветра (ДМК)
                   (1, 6, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]),    -- 200
                   (2, 6, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]),  -- 400
                   (3, 6, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]),  -- 800
                   (4, 6, array[5, 8, 11, 12, 13, 16, 19, 20, 23, 24, 26, 28, 30]),  -- 1200
            -- Таблица 3, Направление среднего ветра (ДМК)
                   (1, 7, array[1]),  -- 200
                   (2, 7, array[2]),  -- 400
                   (3, 7, array[3]),  -- 800
                   (4, 7, array[3]);  -- 1200

        end if;
    end;
    commit;

    -- Прочее: функция расчета поправки к температуре (Таблица 1)
    begin

        -- АДАПТАЦИЯ: в оригинале таблица calc_correction_temperature (temperature, correction),
        -- у нас "расчет_температуры_таблица_1" ("температура", "поправка"). Логика функции не менялась.
        create or replace function public.fn_calc_temperature_interpolation(par_temperature numeric)
            returns numeric
            language plpgsql
            cost 100
            volatile parallel unsafe
        as $BODY$
        declare
            var_interpolation   interpolation_type;
            var_result          numeric(8,2) default 0;
            var_min_temparure   numeric(8,2) default 0;
            var_max_temperature numeric(8,2) default 0;
        begin

            raise notice 'Расчет интерполяции для температуры %', par_temperature;

            -- Проверим, возможно температура совпадает со значением в справочнике
            if exists (select 1 from public."расчет_температуры_таблица_1" where "температура" = par_temperature) then

                select "поправка"
                into var_result
                from public."расчет_температуры_таблица_1"
                where "температура" = par_temperature;

            else

                -- Получим диапазон в котором работают поправки
                select min("температура"), max("температура")
                into var_min_temparure, var_max_temperature
                from public."расчет_температуры_таблица_1";

                if par_temperature < var_min_temparure or
                   par_temperature > var_max_temperature then

                    raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диапазон: %, %',
                        var_min_temparure, var_max_temperature;
                end if;

                -- Получим граничные параметры
                select x0, y0, x1, y1
                into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
                from
                (
                    select t1."температура" as x0, t1."поправка" as y0
                    from public."расчет_температуры_таблица_1" as t1
                    where t1."температура" <= par_temperature
                    order by t1."температура" desc
                    limit 1
                ) as leftPart
                cross join
                (
                    select t1."температура" as x1, t1."поправка" as y1
                    from public."расчет_температуры_таблица_1" as t1
                    where t1."температура" >= par_temperature
                    order by t1."температура"
                    limit 1
                ) as rightPart;

                raise notice 'Граничные значения %', var_interpolation;
                var_result := fn_calc_interpolation(par_temperature, var_interpolation);

            end if;

            return var_result;

        end;
        $BODY$;

        comment on function public.fn_calc_temperature_interpolation(numeric)
            is 'Функция для расчета интерполяции для метео приближенный';

    end;
    commit;

    -- БЛОК 2. ИСПРАВЛЕНИЕ ДАННЫХ СПРАВОЧНИКОВ (Таблица 2, Таблица 3)
    begin

        -- 2.1
        drop table if exists public."значения_справочных_таблиц";
        drop table if exists public."справочные_таблицы_расчета";
        delete from public."типы_оборудования" where "код" = 'EQ-003';

        -- 2.2
        update public."типы_оборудования"
        set "название" = 'ВР (ветровое ружьё)'
        where id = 2 and "название" = 'Метеостанция стационарная';

        -- 2.3 (порядок важен: сначала освобождаем тип 8, потом заполняем его положительными)
        update public.calc_correction
        set type_id = 9
        where type_id = 8 and row_values[1] < 0;

        update public.calc_correction
        set type_id = 8
        where type_id = 7 and array_length(row_values, 1) = 12;

        -- 2.4
        update public.calc_correction
        set row_values = array_prepend(0, row_values)
        where type_id = 9 and array_length(row_values, 1) = 14;

        update public.calc_correction
        set row_values = array_prepend(0, row_values)
        where type_id = 8 and array_length(row_values, 1) = 12;

    end;
    commit;

    -- БЛОК 3. ОТДЕЛЬНАЯ ТАБЛИЦА ЗАГОЛОВКОВ И ИЗМЕНЕНИЕ СПРАВОЧНИКА ТИПОВ ТАБЛИЦ
    begin

        create sequence if not exists calc_correction_headers_seq;
        create table if not exists calc_correction_headers
        (
            id integer not null primary key default nextval('public.calc_correction_headers_seq'),
            description text not null
        );

        comment on table calc_correction_headers is 'Заголовки таблиц корректировок';
        comment on column calc_correction_headers.id is 'Уникальный код';
        comment on column calc_correction_headers.description is 'Описание заголовка';

        create sequence if not exists calc_correction_header_values_seq;
        create table if not exists calc_correction_header_values
        (
            id integer not null primary key default nextval('public.calc_correction_header_values_seq'),
            header_id integer not null,
            column_number integer not null,
            column_value integer not null
        );

        comment on table calc_correction_header_values is 'Значения заголовков таблиц корректировок';
        comment on column calc_correction_header_values.id is 'Уникальный код';
        comment on column calc_correction_header_values.header_id is 'Код заголовка';
        comment on column calc_correction_header_values.column_number is 'Номер столбца (с единицы)';
        comment on column calc_correction_header_values.column_value is 'Значение в заголовке столбца';

        if not exists (select 1 from public.calc_correction_headers) then

            insert into calc_correction_headers(description)
            values ('Таблица 2, положительные отклонения температуры'),
                   ('Таблица 2, отрицательные отклонения температуры'),
                   ('Таблица 3 (ВР), дальность сноса пуль'),
                   ('Таблица 3 (ДМК), скорость ветра у земли');

            insert into calc_correction_header_values(header_id, column_number, column_value)
            select h.id, cast(u.ord as integer), u.val
            from (values
                ('Таблица 2, положительные отклонения температуры', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('Таблица 2, отрицательные отклонения температуры', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
                ('Таблица 3 (ВР), дальность сноса пуль',             array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
                ('Таблица 3 (ДМК), скорость ветра у земли',          array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
            ) as a(descr, arr)
            join calc_correction_headers h on h.description = a.descr
            cross join lateral unnest(a.arr) with ordinality as u(val, ord);

        end if;

        -- Меняем структуру справочника типов таблиц: ссылка на заголовок
        alter table public.calc_correction_types add column if not exists header_id integer;
        comment on column public.calc_correction_types.header_id is 'Код заголовка таблицы';

        update public.calc_correction_types
        set header_id = (select id from public.calc_correction_headers where description = 'Таблица 2, положительные отклонения температуры')
        where id = 8;

        update public.calc_correction_types
        set header_id = (select id from public.calc_correction_headers where description = 'Таблица 2, отрицательные отклонения температуры')
        where id = 9;

        update public.calc_correction_types
        set header_id = (select id from public.calc_correction_headers where description = 'Таблица 3 (ВР), дальность сноса пуль')
        where id in (4, 5);

        update public.calc_correction_types
        set header_id = (select id from public.calc_correction_headers where description = 'Таблица 3 (ДМК), скорость ветра у земли')
        where id in (6, 7);

        -- Массив заголовка больше не нужен: данные перенесены в отдельную таблицу
        alter table public.calc_correction_types drop column if exists header_values;

    end;
    commit;

    -- БЛОК 4. СВЯЗИ И ОГРАНИЧЕНИЯ
	begin

        for r in
            select c.t, c.n, c.d
            from (values
                ('calc_correction_heights',       'uq_calc_correction_heights_height',     'UNIQUE (height)'),
                ('calc_correction_types',         'fk_calc_correction_types_parent',       'FOREIGN KEY (parent_id) REFERENCES calc_correction_types (id)'),
                ('calc_correction_types',         'fk_calc_correction_types_equipment',    'FOREIGN KEY (measurment_equipment_id) REFERENCES "типы_оборудования" (id)'),
                ('calc_correction_types',         'fk_calc_correction_types_header',       'FOREIGN KEY (header_id) REFERENCES calc_correction_headers (id)'),
                ('calc_correction_header_values', 'fk_calc_correction_header_values_hdr', 'FOREIGN KEY (header_id) REFERENCES calc_correction_headers (id) ON DELETE CASCADE'),
                ('calc_correction_header_values', 'uq_calc_correction_header_values_col', 'UNIQUE (header_id, column_number)'),
                ('calc_correction',               'fk_calc_correction_height',             'FOREIGN KEY (height_id) REFERENCES calc_correction_heights (id)'),
                ('calc_correction',               'fk_calc_correction_type',               'FOREIGN KEY (type_id) REFERENCES calc_correction_types (id)'),
                ('calc_correction',               'uq_calc_correction_height_type',        'UNIQUE (height_id, type_id)')
            ) as c(t, n, d)
        loop
            if not exists (select 1 from pg_constraint where conname = r.n) then
                execute format('alter table public.%I add constraint %I %s', r.t, r.n, r.d);
            end if;
        end loop;

    end;
    commit;

    -- БЛОК 5. КОНТРОЛЬ ДАННЫХ
    begin

        select count(*)
        into var_bad
        from public.calc_correction c
        join public.calc_correction_types t on t.id = c.type_id
        where array_length(c.row_values, 1) > 1
          and array_length(c.row_values, 1) <> (select count(*) from public.calc_correction_header_values v where v.header_id = t.header_id);

        raise notice 'Контроль: строк, размер которых не совпадает с заголовком: %', var_bad;

        select count(*)
        into var_bad
        from public.calc_correction_heights h
        where not exists (select 1 from public.calc_correction c where c.height_id = h.id);

        raise notice 'Контроль: стандартных высот без данных корректировок: % (добавить по ТЗ)', var_bad;

    end;
    commit;

end $$;