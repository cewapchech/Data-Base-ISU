-- Скрипт расчета по типовым высотам.
do $$
declare
    var_params public.meteo_params_type;
    r record;
    var_row record;
    var_failed integer := 0;
    var_state text;
begin

    for r in
        select *
        from (values
            (1, 1, 'ДМК: температура 20, скорость ветра 8', 20::numeric, 8::numeric, null::numeric),
            (2, 2, 'ВР: температура 5, дальность сноса пуль 85', 5::numeric, null::numeric, 85::numeric),
            (3, 1, 'ДМК: температура 10, скорость ветра 7,5', 10::numeric, 7.5::numeric, null::numeric)
        ) as s(n, equipment_id, title, t, speed, drift)
        order by n
    loop

        var_params.height := 150;
        var_params.temperature := r.t;
        var_params.pressure := 750;
        var_params.wind_direction := 90;
        var_params.wind_speed := r.speed;
        var_params.bullet_drift := r.drift;

        raise notice '=== Сценарий %: % ===', r.n, r.title;

        for var_row in
            select
                c.standard_height,
                c.temperature_deviation,
                c.wind_speed_avg,
                c.wind_direction_correction,
                e.dt, e.sp, e.dr
            from public.sp_calc_meteo_by_heights(var_params, r.equipment_id) c
            left join (values
                (1,  200,  5.10, 12.00, 1), (1,  400,  5.10, 14.00, 2), (1,  800,  5.10, 15.00, 3), (1, 1200,  5.10, 16.00, 3),
                (2,  200, -9.44,  7.00, 0), (2,  400, -9.40,  8.50, 1), (2,  800, -8.40,  8.50, 2), (2, 1200, -8.36,  8.50, 2),
                (3,  200, -4.90, 11.00, 1), (3,  400, -4.90, 13.00, 2), (3,  800, -4.90, 14.00, 3), (3, 1200, -4.00, 14.50, 3)
            ) as e(n, h, dt, sp, dr)
              on e.n = r.n and e.h = c.standard_height
            order by c.standard_height
        loop

            if var_row.dt is null then
                var_state := 'эталона нет';
            elsif abs(coalesce(var_row.temperature_deviation, 9999) - var_row.dt) < 0.001
              and abs(coalesce(var_row.wind_speed_avg, 9999) - var_row.sp) < 0.001
              and var_row.wind_direction_correction = var_row.dr then
                var_state := 'ОК';
            else
                var_state := 'ОШИБКА';
                var_failed := var_failed + 1;
            end if;

            raise notice 'высота % м: отклонение температуры = %, скорость ветра = %, поправка направления = %  [%]',
                var_row.standard_height,
                coalesce(var_row.temperature_deviation::text, 'нет данных'),
                coalesce(var_row.wind_speed_avg::text, 'нет данных'),
                coalesce(var_row.wind_direction_correction::text, 'нет данных'),
                var_state;

        end loop;
    end loop;

    if var_failed = 0 then
        raise notice 'ИТОГ: все контрольные значения совпали';
    else
        raise exception 'ИТОГ: расхождений с контрольными значениями: %', var_failed;
    end if;

end $$;

-- Тот же расчет в виде таблицы (для сценария 1). Выделить и выполнить отдельно.
select *
from public.sp_calc_meteo_by_heights(
    row(150, 20, 750, 90, 8, null)::public.meteo_params_type,
    1
);