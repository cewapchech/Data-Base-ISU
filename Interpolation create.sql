-- Интерполяция поправки к температуре
-- PostgreSQL 16, база study2025, схема public
-- Использует таблицу "расчет_температуры_таблица_1" (температура, поправка)
do $$
begin

    -- Тип данных для интерполяции: две соседние точки (x0, y0) и (x1, y1)
    if not exists (
        select 1
        from pg_type t
        join pg_namespace n on n.oid = t.typnamespace
        where n.nspname = 'public' and t.typname = 'interpolation_type'
    ) then
        create type public.interpolation_type as (
            x0 numeric,
            y0 numeric,
            x1 numeric,
            y1 numeric
        );
    end if;

    -- Функция 1: по температуре находит границы для интерполяции
    -- Температура вне таблицы приводится к ближайшему краю таблицы
    -- при точном совпадении нижняя и верхняя граница — одна и та же строка
    create or replace function public.fn_get_interpolation_params(par_temperature numeric)
    returns public.interpolation_type
    language plpgsql
    as $body$
    declare
        var_interpolation public.interpolation_type;
        var_temperature   numeric;
    begin
        var_temperature := least(
            greatest(par_temperature, (select min("температура") from public."расчет_температуры_таблица_1")),
            (select max("температура") from public."расчет_температуры_таблица_1")
        );

        select
            low_bound."температура",
            low_bound."поправка",
            high_bound."температура",
            high_bound."поправка"
        into
            var_interpolation.x0,
            var_interpolation.y0,
            var_interpolation.x1,
            var_interpolation.y1
        from
            -- Нижняя граница
            (
                select "температура", "поправка"
                from public."расчет_температуры_таблица_1"
                where "температура" <= var_temperature
                order by "температура" desc
                limit 1
            ) as low_bound,
            -- Верхняя граница
            (
                select "температура", "поправка"
                from public."расчет_температуры_таблица_1"
                where "температура" >= var_temperature
                order by "температура" asc
                limit 1
            ) as high_bound;

        return var_interpolation;
    end;
    $body$;

    -- Функция 2: линейная интерполяция y для произвольного x по структуре
    create or replace function public.fn_calc_interpolation(
        par_x numeric,
        par_interpolation public.interpolation_type
    )
    returns numeric
    language plpgsql
    as $body$
    begin
        -- границы совпали (точное значение или край таблицы) делить на ноль нельзя
        if par_interpolation.x1 = par_interpolation.x0 then
            return par_interpolation.y0;
        end if;

        return par_interpolation.y0
             + (par_x - par_interpolation.x0)
               * (par_interpolation.y1 - par_interpolation.y0)
               / (par_interpolation.x1 - par_interpolation.x0);
    end;
    $body$;

end $$;
