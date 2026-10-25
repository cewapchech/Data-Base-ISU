-- Проверки интерполяции
-- Таблица: (0; 0,5) (5; 0,5) (10; 1) (20; 1) (25; 2) (30; 3,5) (40; 4,5)
do $$
declare
    r record;
    var_params public.interpolation_type;
    var_result numeric;
    var_failed integer := 0;
begin

    -- Проверка 1. Границы интерполяции (x0, y0, x1, y1)
    for r in
        select *
        from (values
            (1, 'внутри таблицы', 27::numeric, 25::numeric, 2::numeric, 30::numeric, 3.5::numeric),
            (2, 'выше таблицы', 50::numeric, 40::numeric, 4.5::numeric, 40::numeric, 4.5::numeric),
            (3, 'ниже таблицы', -10::numeric, 0::numeric, 0.5::numeric, 0::numeric, 0.5::numeric),
            (4, 'точное значение', 20::numeric, 20::numeric, 1::numeric, 20::numeric, 1::numeric)
        ) as c(n, descr, t, ex0, ey0, ex1, ey1)
        order by n
    loop
        var_params := public.fn_get_interpolation_params(r.t);

        if var_params.x0 = r.ex0 and var_params.y0 = r.ey0
           and var_params.x1 = r.ex1 and var_params.y1 = r.ey1 then
            raise notice 'Границы %: % (t=%) - ОК: (%; %) (%; %)',
                r.n, r.descr, r.t, var_params.x0, var_params.y0, var_params.x1, var_params.y1;
        else
            var_failed := var_failed + 1;
            raise notice 'Границы %: % (t=%) - ОШИБКА: получили (%; %) (%; %), ожидали (%; %) (%; %)',
                r.n, r.descr, r.t, var_params.x0, var_params.y0, var_params.x1, var_params.y1,
                r.ex0, r.ey0, r.ex1, r.ey1;
        end if;
    end loop;

    -- Проверка 2. Рассчитанная поправка y для температуры x
    for r in
        select *
        from (values
            (1, 'узел таблицы', 0::numeric, 0.5::numeric),
            (2, 'ровный участок 0-5', 2::numeric, 0.5::numeric),
            (3, 'между 5 и 10', 7.5::numeric, 0.75::numeric),
            (4, 'ровный участок 10-20', 16.5::numeric, 1::numeric),
            (5, 'между 20 и 25', 22.5::numeric, 1.5::numeric),
            (6, 'между 25 и 30', 27::numeric, 2.6::numeric),
            (7, 'между 30 и 40', 35::numeric, 4::numeric),
            (8, 'верхний край таблицы', 40::numeric, 4.5::numeric),
            (9, 'выше таблицы (берётся край)', 50::numeric, 4.5::numeric),
            (10, 'ниже таблицы (берётся край)', -10::numeric, 0.5::numeric)
        ) as c(n, descr, x, expected)
        order by n
    loop
        var_params := public.fn_get_interpolation_params(r.x);
        var_result := public.fn_calc_interpolation(r.x, var_params);

        if abs(var_result - r.expected) < 0.0001 then
            raise notice 'Расчет %: % (t=%) - ОК: y = %', r.n, r.descr, r.x, round(var_result, 4);
        else
            var_failed := var_failed + 1;
            raise notice 'Расчет %: % (t=%) - ОШИБКА: получили %, ожидали %',
                r.n, r.descr, r.x, round(var_result, 4), r.expected;
        end if;
    end loop;

    if var_failed = 0 then
        raise notice 'ИТОГ: все проверки пройдены';
    else
        raise exception 'ИТОГ: не пройдено проверок: %', var_failed;
    end if;

end $$;
