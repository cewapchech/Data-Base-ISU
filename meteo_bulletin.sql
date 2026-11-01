-- Метео, шаг 4: функции "Метео приближенный" (ДДЧЧМ, ВВВВ, БББТТ).
-- ДДЧЧМ - день, час и десятки минут измерения
-- ВВВВ  - высота метеопоста, 4 цифры
-- БББТТ - отклонение давления от нормального (3 цифры) и отклонение температуры от нормальной (2 цифры)
do $$
begin

    -- Вложенная транзакция 1
    -- Функции расчета групп
    begin
        -- ДДЧЧМ
        create or replace function public.fn_meteo_ddchhm(par_date date, par_time time)
        returns text
        language plpgsql
        as $body$
        begin
            return to_char(par_date, 'DD')
                || to_char(par_time, 'HH24')
                || cast(floor(extract(minute from par_time) / 10) as integer)::text;
        end;
        $body$;

        -- ВВВВ
        create or replace function public.fn_meteo_vvvv(par_height numeric)
        returns text
        language plpgsql
        as $body$
        begin
            if par_height < 0 or par_height > 9999 then
                raise exception 'Высота метеопоста % не помещается в группу ВВВВ', par_height;
            end if;

            return lpad(cast(round(par_height) as integer)::text, 4, '0');
        end;
        $body$;

        -- Кодирование отклонения: отрицательное = модуль + смещение
        create or replace function public.fn_meteo_encode(par_value numeric, par_width integer, par_offset numeric)
        returns text
        language plpgsql
        as $body$
        begin
            if par_value >= 0 then
                return lpad(cast(par_value as integer)::text, par_width, '0');
            end if;

            return lpad(cast(abs(par_value) + par_offset as integer)::text, par_width, '0');
        end;
        $body$;

        -- БББТТ
        create or replace function public.fn_meteo_bbbtt(par_pressure numeric, par_temperature numeric)
        returns text
        language plpgsql
        as $body$
        declare
            var_dp     numeric;
            var_dt     numeric;
            var_params public.interpolation_type;
        begin
            var_dp := round(par_pressure - public.fn_get_meteo_const('NORM_PRESSURE'));

            var_params := public.fn_get_interpolation_params(par_temperature);
            var_dt := round(
                par_temperature
                + public.fn_calc_interpolation(par_temperature, var_params)
                - public.fn_get_meteo_const('NORM_TEMPERATURE')
            );

            return public.fn_meteo_encode(var_dp, 3, public.fn_get_meteo_const('OFFSET_NEG_PRESSURE'))
                || public.fn_meteo_encode(var_dt, 2, public.fn_get_meteo_const('OFFSET_NEG_TEMPERATURE'));
        end;
        $body$;

        -- Метео приближенный для пачки: "ДДЧЧМ ВВВВ БББТТ"
        create or replace function public.fn_meteo_approx(par_batch_id integer)
        returns text
        language plpgsql
        as $body$
        declare
            var_date   date;
            var_time   time;
            var_params public.meteo_params_type;
        begin
            select b."дата_измерения", b."время_измерения"
            into var_date, var_time
            from public."пачки" b
            where b.id = par_batch_id;

            var_params := public.fn_get_batch_params(par_batch_id);

            return public.fn_meteo_ddchhm(var_date, var_time)
                || ' ' || public.fn_meteo_vvvv(var_params.height)
                || ' ' || public.fn_meteo_bbbtt(var_params.pressure, var_params.temperature);
        end;
        $body$;
    end;
    commit;

end $$;
