-- шаг 3: проверка входных параметров.
do $$
begin

    -- Вложенная транзакция 1
    -- Расширяем DDL: информация об ошибках для входных параметров
    begin
        alter table public."параметры" add column if not exists "есть_ошибка" boolean not null default false;
        alter table public."параметры" add column if not exists "описание_ошибки" varchar(500);
    end;
    commit;

    -- Вложенная транзакция 2
    -- Новый тип данных "список параметров" и функции проверки
    begin
        if not exists (
            select 1
            from pg_type t
            join pg_namespace n on n.oid = t.typnamespace
            where n.nspname = 'public' and t.typname = 'meteo_params_type'
        ) then
            create type public.meteo_params_type as (
                height         numeric,  -- высота метеопоста
                temperature    numeric,  -- температура
                pressure       numeric,  -- давление
                wind_direction numeric,  -- направление ветра
                wind_speed     numeric,  -- скорость ветра
                bullet_drift   numeric   -- дальность сноса пуль
            );
        end if;

        -- Проверка одного значения: пустая строка NULL означает "ошибок нет"
        create or replace function public.fn_check_param_value(par_type_id integer, par_value numeric)
        returns text
        language plpgsql
        as $body$
        declare
            var_name  text;
            var_limit public.param_limit_type;
        begin
            select t."название" into var_name
            from public."типы_параметров" t
            where t.id = par_type_id;

            if par_value is null then
                return format('%s: значение не задано', var_name);
            end if;

            var_limit := public.fn_get_param_limit(par_type_id);

            -- для типа параметра диапазон не задан — проверять нечего
            if var_limit.min_value is null then
                return null;
            end if;

            if par_value < var_limit.min_value or par_value > var_limit.max_value then
                return format('%s: значение %s вне диапазона [%s; %s]',
                    var_name,
                    trim_scale(par_value),
                    trim_scale(var_limit.min_value),
                    trim_scale(var_limit.max_value));
            end if;

            return null;
        end;
        $body$;

        -- Проверка списка параметров: на входе тип со списком, на выходе строка со списком ошибок
        -- (пустая строка, если ошибок нет)
        create or replace function public.fn_check_meteo_params(par_params public.meteo_params_type)
        returns text
        language plpgsql
        as $body$
        declare
            var_errors text[] := array[]::text[];
            var_msg    text;
            r          record;
        begin
            for r in
                select c.code, c.val
                from (values
                    ('TYP-006', par_params.height),
                    ('TYP-007', par_params.temperature),
                    ('TYP-008', par_params.pressure),
                    ('TYP-009', par_params.wind_direction),
                    ('TYP-010', par_params.wind_speed),
                    ('TYP-011', par_params.bullet_drift)
                ) as c(code, val)
            loop
                var_msg := public.fn_check_param_value(
                    (select t.id from public."типы_параметров" t where t."код" = r.code),
                    r.val
                );

                if var_msg is not null then
                    var_errors := array_append(var_errors, var_msg);
                end if;
            end loop;

            return array_to_string(var_errors, '; ');
        end;
        $body$;

        -- Собирает список параметров пачки из строк таблицы "параметры"
        create or replace function public.fn_get_batch_params(par_batch_id integer)
        returns public.meteo_params_type
        language plpgsql
        as $body$
        declare
            var_params public.meteo_params_type;
        begin
            select
                max(p."значение") filter (where t."код" = 'TYP-006'),
                max(p."значение") filter (where t."код" = 'TYP-007'),
                max(p."значение") filter (where t."код" = 'TYP-008'),
                max(p."значение") filter (where t."код" = 'TYP-009'),
                max(p."значение") filter (where t."код" = 'TYP-010'),
                max(p."значение") filter (where t."код" = 'TYP-011')
            into
                var_params.height,
                var_params.temperature,
                var_params.pressure,
                var_params.wind_direction,
                var_params.wind_speed,
                var_params.bullet_drift
            from public."параметры" p
            join public."типы_параметров" t on t.id = p."тип_параметра_id"
            where p."пачка_id" = par_batch_id;

            return var_params;
        end;
        $body$;

        -- Проставляет флаг и описание ошибки в каждой строке "параметры",
        -- возвращает количество строк с ошибками
        create or replace function public.fn_refresh_param_errors()
        returns integer
        language plpgsql
        as $body$
        declare
            var_count integer;
        begin
            update public."параметры" p
            set "описание_ошибки" = e.msg,
                "есть_ошибка"     = (e.msg is not null)
            from (
                select x.id, public.fn_check_param_value(x."тип_параметра_id", x."значение") as msg
                from public."параметры" x
            ) as e
            where p.id = e.id;

            select count(*) into var_count
            from public."параметры"
            where "есть_ошибка";

            return var_count;
        end;
        $body$;
    end;
    commit;

    -- Вложенная транзакция 3
    -- Проставляем ошибки в уже загруженных данных
    begin
        perform public.fn_refresh_param_errors();
    end;
    commit;

end $$;
