--  шаг 2: константы. Таблицы констант, структура и функции доступа к ним.

do $$
declare
    max_meteo_constants integer;
    max_param_limits    integer;
    r                   record;
begin

    -- Вложенная транзакция 1
    -- Таблицы констант, счетчики, структура и функции доступа
    begin
        create table if not exists "константы_метео" (
            id integer not null,
            "код" varchar(30) not null,
            "название" varchar(100) not null,
            "значение" numeric(12,4) not null
        );

        create table if not exists "ограничения_параметров" (
            id integer not null,
            "код" varchar(20) not null,
            "тип_параметра_id" integer not null,
            "мин_значение" numeric(12,2) not null,
            "макс_значение" numeric(12,2) not null
        );

        create sequence if not exists seq_meteo_constants;
        create sequence if not exists seq_param_limits;

        alter table public."константы_метео" alter column id set default nextval('public.seq_meteo_constants');
        alter table public."ограничения_параметров" alter column id set default nextval('public.seq_param_limits');

        alter sequence seq_meteo_constants owned by public."константы_метео".id;
        alter sequence seq_param_limits owned by public."ограничения_параметров".id;

        -- структура для хранения допустимого диапазона
        if not exists (
            select 1
            from pg_type t
            join pg_namespace n on n.oid = t.typnamespace
            where n.nspname = 'public' and t.typname = 'param_limit_type'
        ) then
            create type public.param_limit_type as (
                min_value numeric,
                max_value numeric
            );
        end if;

        -- значение константы по коду
        create or replace function public.fn_get_meteo_const(par_code varchar)
        returns numeric
        language plpgsql
        as $body$
        declare
            var_value numeric;
        begin
            select c."значение"
            into var_value
            from public."константы_метео" c
            where c."код" = par_code;

            if not found then
                raise exception 'Константа % не найдена', par_code;
            end if;

            return var_value;
        end;
        $body$;

        -- допустимый диапазон для типа параметра (если не задан - оба поля пустые)
        create or replace function public.fn_get_param_limit(par_type_id integer)
        returns public.param_limit_type
        language plpgsql
        as $body$
        declare
            var_limit public.param_limit_type;
        begin
            select l."мин_значение", l."макс_значение"
            into var_limit.min_value, var_limit.max_value
            from public."ограничения_параметров" l
            where l."тип_параметра_id" = par_type_id;

            return var_limit;
        end;
        $body$;
    end;
    commit;

    -- Вложенная транзакция 2
    -- Значения констант и диапазонов
    begin
        insert into "константы_метео" (id, "код", "название", "значение")
        select v.id, v.k, v.n, v.val
        from (values
            (1, 'NORM_PRESSURE',          'Нормальное давление, мм рт. ст.',                          750),
            (2, 'NORM_TEMPERATURE',       'Нормальная температура, °C',                               15.9),
            (3, 'OFFSET_NEG_PRESSURE',    'Смещение кода при отрицательном отклонении давления',      500),
            (4, 'OFFSET_NEG_TEMPERATURE', 'Смещение кода при отрицательном отклонении температуры',    50)
        ) as v(id, k, n, val)
        where not exists (select 1 from "константы_метео" t where t.id = v.id);

        -- допустимые диапазоны по типам параметров (6-11 из шага 1)
        insert into "ограничения_параметров" (id, "код", "тип_параметра_id", "мин_значение", "макс_значение")
        select v.id, v.k, v.t, v.mn, v.mx
        from (values
            (1, 'LIM-006', 6,  0,   5000),
            (2, 'LIM-007', 7,  -50, 50),
            (3, 'LIM-008', 8,  500, 800),
            (4, 'LIM-009', 9,  0,   360),
            (5, 'LIM-010', 10, 0,   30),
            (6, 'LIM-011', 11, 0,   1000)
        ) as v(id, k, t, mn, mx)
        where not exists (select 1 from "ограничения_параметров" t where t.id = v.id);

        max_meteo_constants := (select max(id) from public."константы_метео");
        max_param_limits    := (select max(id) from public."ограничения_параметров");

        perform setval('public.seq_meteo_constants', max_meteo_constants);
        perform setval('public.seq_param_limits', max_param_limits);
    end;
    commit;

    -- Вложенная транзакция 3
    -- Ограничения и связи
    begin
        for r in
            select c.t, c.n, c.d
            from (values
                ('константы_метео',        'pk_константы_метео',            'PRIMARY KEY (id)'),
                ('константы_метео',        'uq_константы_метео_код',        'UNIQUE ("код")'),
                ('ограничения_параметров', 'pk_ограничения_параметров',     'PRIMARY KEY (id)'),
                ('ограничения_параметров', 'uq_ограничения_параметров_код', 'UNIQUE ("код")'),
                ('ограничения_параметров', 'uq_ограничения_тип',            'UNIQUE ("тип_параметра_id")'),
                ('ограничения_параметров', 'fk_ограничения_тип',            'FOREIGN KEY ("тип_параметра_id") REFERENCES "типы_параметров" (id)'),
                ('ограничения_параметров', 'ck_ограничения_диапазон',       'CHECK ("макс_значение" >= "мин_значение")')
            ) as c(t, n, d)
        loop
            if not exists (select 1 from pg_constraint where conname = r.n) then
                execute format('alter table public.%I add constraint %I %s', r.t, r.n, r.d);
            end if;
        end loop;
    end;
    commit;

end $$;
