-- шаг 5: запросы. Каждый запрос выполнять отдельно

-- Запрос 1. Список параметров с ошибками
with meteo_batches as (
    -- пачки метеоизмерений (у них задан тип оборудования)
    select b.id, b."код" as batch_code, e."название" as equipment_name
    from public."пачки" b
    join public."типы_оборудования" e on e.id = b."тип_оборудования_id"
),
batch_params as (
    -- проекция: строки параметров превращаем в колонки
    select
        p."пачка_id",
        max(p."значение") filter (where t."код" = 'TYP-006') as height,
        max(p."значение") filter (where t."код" = 'TYP-007') as temperature,
        max(p."значение") filter (where t."код" = 'TYP-008') as pressure,
        max(p."значение") filter (where t."код" = 'TYP-009') as wind_direction,
        max(p."значение") filter (where t."код" = 'TYP-010') as wind_speed,
        max(p."значение") filter (where t."код" = 'TYP-011') as bullet_drift
    from public."параметры" p
    join public."типы_параметров" t on t.id = p."тип_параметра_id"
    group by p."пачка_id"
),
checked as (
    -- проверка списка параметров функцией
    select
        m.batch_code,
        m.equipment_name,
        bp.height,
        bp.temperature,
        bp.pressure,
        bp.wind_direction,
        bp.wind_speed,
        bp.bullet_drift,
        public.fn_check_meteo_params(
            row(bp.height, bp.temperature, bp.pressure, bp.wind_direction, bp.wind_speed, bp.bullet_drift)
            ::public.meteo_params_type
        ) as errors
    from meteo_batches m
    join batch_params bp on bp."пачка_id" = m.id
)
select
    c.batch_code        as "№",
    c.equipment_name    as "Тип оборудования",
    c.height            as "Высота метеопоста",
    c.temperature       as "Температура",
    c.pressure          as "Давление",
    c.wind_direction    as "Направление ветра",
    c.wind_speed        as "Скорость ветра",
    c.bullet_drift      as "Дальность сноса пуль",
    case when c.errors <> '' then 'Да' else 'Нет' end as "Флаг: Есть ошибка",
    c.errors            as "Описание ошибки"
from checked c
order by c.batch_code;

-- Запрос 2. Лучший стрелок
with user_errors as (
    select
        u.id,
        u."имя"                                      as user_name,
        count(distinct b.id)                         as batches_count,
        count(p.id) filter (where p."есть_ошибка")   as errors_count
    from public."пользователи" u
    left join public."пачки" b
           on b."пользователь_id" = u.id
          and b."тип_оборудования_id" is not null
    left join public."параметры" p on p."пачка_id" = b.id
    group by u.id, u."имя"
)
select
    dense_rank() over (order by e.errors_count)  as "Место",
    e.user_name                                  as "Стрелок",
    e.batches_count                              as "Пачек",
    e.errors_count                               as "Количество ошибок",
    round(100.0 * e.errors_count / nullif(sum(e.errors_count) over (), 0), 1)
                                                 as "Доля всех ошибок, %",
    case when rank() over (order by e.errors_count) = 1
         then 'Лучший стрелок' else '' end       as "Отметка"
from user_errors e
order by "Место", e.user_name;

-- Запрос 3. Метео приближенный по пачкам
select
    b."код"                       as "№",
    public.fn_meteo_approx(b.id)  as "ДДЧЧМ ВВВВ БББТТ"
from public."пачки" b
where b."тип_оборудования_id" is not null
order by b."код";
