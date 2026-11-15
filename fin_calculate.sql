do $$
begin

    -- Значение корректировки для типа таблицы, высоты и аргумента.
    -- Если в строке одно значение (направление ветра), оно и возвращается.
    -- Иначе значение между столбцами заголовка находится интерполяцией (fn_calc_interpolation).
    create or replace function public.fn_calc_correction(par_type_id integer, par_height_id integer, par_x numeric)
    returns numeric
    language plpgsql
    as $body$
    declare
        var_header integer[];
        var_row integer[];
        var_count integer;
        var_i integer;
        var_interpolation public.interpolation_type;
    begin
        select c.row_values
        into var_row
        from public.calc_correction c
        where c.type_id = par_type_id
          and c.height_id = par_height_id;

        -- для этой высоты данных пока нет
        if var_row is null then
            return null;
        end if;

        -- одно значение на высоту: заголовок не нужен
        if array_length(var_row, 1) = 1 then
            return var_row[1];
        end if;

        select array_agg(v.column_value order by v.column_number)
        into var_header
        from public.calc_correction_types t
        join public.calc_correction_header_values v on v.header_id = t.header_id
        where t.id = par_type_id;

        var_count := array_length(var_header, 1);

        if var_header is null or var_count <> array_length(var_row, 1) then
            raise exception 'Заголовок и строка таблицы не совпадают по размеру (тип %, высота %)', par_type_id, par_height_id;
        end if;

        if par_x < var_header[1] or par_x > var_header[var_count] then
            raise exception 'Значение % вне диапазона таблицы [%; %] (тип %)', par_x, var_header[1], var_header[var_count], par_type_id;
        end if;

        -- первый столбец заголовка, который не меньше аргумента
        var_i := 1;
        while var_header[var_i] < par_x loop
            var_i := var_i + 1;
        end loop;

        -- аргумент совпал со столбцом заголовка
        if var_header[var_i] = par_x then
            return var_row[var_i];
        end if;

        var_interpolation.x0 := var_header[var_i - 1];
        var_interpolation.y0 := var_row[var_i - 1];
        var_interpolation.x1 := var_header[var_i];
        var_interpolation.y1 := var_row[var_i];

        return public.fn_calc_interpolation(par_x, var_interpolation);
    end;
    $body$;

    -- Хранимая процедура расчета
    create or replace function public.sp_calc_meteo_by_heights(
        par_params public.meteo_params_type,
        par_equipment_id integer
    )
    returns table (
        standard_height integer,
        temperature_deviation numeric,
        wind_speed_avg numeric,
        wind_direction_correction numeric
    )
    language plpgsql
    as $body$
    declare
        var_deviation numeric;
        var_x_wind numeric;
        var_type_t2 integer;
        var_type_speed integer;
        var_type_dir integer;
        r record;
    begin
        -- Для ДМК аргумент Таблицы 3 - скорость ветра у земли, для ВР (тип 2) - дальность сноса пуль
        if par_equipment_id = 2 then
            var_x_wind := par_params.bullet_drift;
        else
            var_x_wind := par_params.wind_speed;
        end if;

        if par_params.temperature is null or var_x_wind is null then
            raise exception 'Не заданы входные параметры для расчета (температура и % )',
                case when par_equipment_id = 2 then 'дальность сноса пуль' else 'скорость ветра' end;
        end if;

        -- Отклонение температуры у земли от нормальной с поправкой из Таблицы 1
        var_deviation := par_params.temperature
                       + public.fn_calc_temperature_interpolation(par_params.temperature)
                       - public.fn_get_meteo_const('NORM_TEMPERATURE');

        -- Таблица 2: знак отклонения выбирает таблицу (положительные или отрицательные)
        select t.id
        into var_type_t2
        from public.calc_correction_types t
        where t.parent_id = 1
          and t.description like case when var_deviation >= 0 then '%Положительные%' else '%Отрицательные%' end;

        -- Таблица 3: скорость (родитель 2) и направление (родитель 3) для типа оборудования
        select t.id
        into var_type_speed
        from public.calc_correction_types t
        where t.parent_id = 2 and t.measurment_equipment_id = par_equipment_id;

        select t.id
        into var_type_dir
        from public.calc_correction_types t
        where t.parent_id = 3 and t.measurment_equipment_id = par_equipment_id;

        if var_type_t2 is null or var_type_speed is null or var_type_dir is null then
            raise exception 'Для типа оборудования % нет таблиц корректировок', par_equipment_id;
        end if;

        -- Расчет по каждой стандартной высоте
        for r in
            select h.id as height_id, h.height as height_value
            from public.calc_correction_heights h
            order by h.height
        loop
            standard_height := r.height_value;
            temperature_deviation := round(public.fn_calc_correction(var_type_t2, r.height_id, abs(var_deviation)), 2);
            wind_speed_avg := round(public.fn_calc_correction(var_type_speed, r.height_id, var_x_wind), 2);
            wind_direction_correction := round(public.fn_calc_correction(var_type_dir, r.height_id, var_x_wind), 2);
            return next;
        end loop;
    end;
    $body$;

    comment on function public.sp_calc_meteo_by_heights(public.meteo_params_type, integer)
        is 'Расчет корректировок по каждой стандартной высоте: входящие параметры и тип оборудования';

end $$;