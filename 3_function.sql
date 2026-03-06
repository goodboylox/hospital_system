CREATE OR REPLACE VIEW hospital.doctor_info
AS SELECT dd.id,
    dd.first_name AS "Имя",
    dd.second_name AS "Фамилия",
    dd.third_name AS "Отчество",
    COALESCE(dp.position_name, 'Без должности'::character varying) AS "Должность"
   FROM hospital.dict_doctors dd
     LEFT JOIN hospital.map_prof mp ON dd.id = mp.doctor_id AND CURRENT_DATE >= mp.start_date AND CURRENT_DATE <= mp.end_date
     LEFT JOIN hospital.dict_positions dp ON dd.id = dp.id AND dp.is_active
  WHERE dd.is_active;

CREATE MATERIALIZED VIEW hospital.treatment
TABLESPACE pg_default
AS SELECT (((p.second_name::text || ' '::text) || p.first_name::text) || ' '::text) || p.third_name::text AS "ФИО пациента",
    p.oms_name AS "ОМС",
    ds.disease_name AS "Заболевание",
    mp2d.start_date AS "Начало заболевания",
    mp2d.end_date AS "Конец заболевания",
    string_agg(s.symptom_name, ', '::text) AS "Симптомы",
        CASE
            WHEN mp2d.is_other_therapy THEN mp2d.other_therapy
            ELSE ds.therapy_name
        END AS "Лечение",
    (((d.second_name::text || ' '::text) || d.first_name::text) || ' '::text) || d.third_name::text AS "ФИО врача",
    dp.position_name AS "Должность",
    CURRENT_DATE AS "Текущая дата"
   FROM hospital.map_patients2diseases mp2d
     JOIN hospital.dict_patients p ON mp2d.patient_id = p.id AND p.is_active IS TRUE
     LEFT JOIN hospital.dict_doctors d ON mp2d.doctor_id = d.id AND d.is_active IS TRUE
     JOIN hospital.dict_diseases ds ON mp2d.disease_id = ds.id AND ds.is_active IS TRUE
     JOIN hospital.map_diseases2symptoms md2s ON mp2d.id = md2s.patients2diseases_id
     JOIN hospital.dict_symptoms s ON md2s.symptom_id = s.id
     LEFT JOIN hospital.map_prof mp ON d.id = mp.doctor_id AND CURRENT_DATE >= mp.start_date AND CURRENT_DATE <= mp.end_date
     LEFT JOIN hospital.dict_positions dp ON dp.id = mp.position_id
  GROUP BY ((((p.second_name::text || ' '::text) || p.first_name::text) || ' '::text) || p.third_name::text), p.oms_name, ds.disease_name, mp2d.start_date, mp2d.end_date, (
        CASE
            WHEN mp2d.is_other_therapy THEN mp2d.other_therapy
            ELSE ds.therapy_name
        END), ((((d.second_name::text || ' '::text) || d.first_name::text) || ' '::text) || d.third_name::text), dp.position_name
WITH DATA;

-- DROP FUNCTION hospital.add_deseases_case(int8, int8, int8, _int8, text);

CREATE OR REPLACE FUNCTION hospital.add_deseases_case(p_patient_id bigint, p_doctor_id bigint, p_disease_id bigint, p_symptom_id bigint[], p_other_therapy text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
	v_patients2diseases_id int8;
begin
	if (select count(*) from hospital.dict_patients 
		where id = p_patient_id 
		and is_active)<1 then
		raise notice 'Пациент не существует';
		return false;
	end if;

	if (select count(*) from hospital.dict_doctors 
		where id = p_doctor_id 
		and is_active)<1 then
		raise notice 'Доктор не существует';
		return false;
	end if;

	if (select count(*) from hospital.dict_diseases
		where id = p_disease_id
		and is_active)<1 then
		raise notice 'Заболевание не найдено в базе данных';
		return false;
	end if;

	insert into hospital.map_patients2diseases
	(patient_id, disease_id, doctor_id, start_date, is_other_therapy, other_therapy)
	select p_patient_id, p_disease_id, p_doctor_id, current_date, p_other_therapy is not null, p_other_therapy;
	
	v_patients2diseases_id:= (select id from hospital.map_patients2diseases
	where patient_id = p_patient_id and disease_id = p_disease_id and doctor_id = p_doctor_id
	order by created_dttm desc
	limit 1);
		
	drop table if exists t_symptoms;

	create temp table t_symptoms as 
		select symptom_id 
		from unnest (p_symptom_id) symptom_id
		join hospital.dict_symptoms ds
		on ds.id = symptom_id;
	
	insert into hospital.map_diseases2symptoms
	(patients2diseases_id, symptom_id, is_active)
	select v_patients2diseases_id, symptom_id, true
	from t_symptoms;
	
	drop table if exists t_symptoms;
	return true;
end;
$function$
;

-- DROP FUNCTION hospital.add_doctors(varchar, varchar, varchar, date, bool);

CREATE OR REPLACE FUNCTION hospital.add_doctors(p_first_name character varying, p_second_name character varying, p_third_name character varying, p_birth_date date, p_is_active boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
	v_doctor_id int8;
	v_name_unique bool;
begin
	select count(*)>=1 into v_name_unique
	from hospital.dict_doctors
	where first_name = p_first_name
		and second_name = p_second_name
		and third_name = p_third_name;
	
	if v_name_unique then
		raise notice 'Врач с данным ФИО "% % %" уже существует', p_first_name, p_second_name,  p_third_name;
		return false;
	end if;
	
	if p_birth_date <= current_date - interval '120 years' 
	or p_birth_date >= current_date - interval '24 years' then
		raise notice 'Возвраст врача вне диапазона 24-120 лет для даты рождения %', p_birth_date;
		return false;
	end if;
	
	insert into hospital.dict_doctors (first_name, second_name, third_name, birth_date, is_active)
	values (p_first_name, p_second_name, p_third_name, p_birth_date, p_is_active);
	return true;
	
	exception when others then 
		raise notice 'Ошибка добавления врача "% % %"', p_first_name, p_second_name,  p_third_name;
		return false;
end;
$function$
;

-- DROP FUNCTION hospital.add_doctors(varchar, varchar, varchar, date, int8, bool);

CREATE OR REPLACE FUNCTION hospital.add_doctors(p_first_name character varying, p_second_name character varying, p_third_name character varying, p_birth_date date, p_position_id bigint, p_is_active boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
	v_doctor_id int8;
	v_name_unique bool;
begin
	select count(*)>=1 into v_name_unique
	from hospital.dict_doctors
	where first_name = p_first_name
		and second_name = p_second_name
		and third_name = p_third_name;
	
	if v_name_unique then
		raise notice 'Врач с данным ФИО "% % %" уже существует', p_first_name, p_second_name,  p_third_name;
		return false;
	end if;
	
	if p_birth_date <= current_date - interval '120 years' 
	or p_birth_date >= current_date - interval '24 years' then
		raise notice 'Возвраст врача вне диапазона 24-120 лет для даты рождения %', p_birth_date;
		return false;
	end if;
	
	if (select count(*) from hospital.dict_positions
		where id = p_position_id) <1
		then 
		raise notice 'Данной позиции не существует %', p_position_id;
		return false;
	end if;
	
	insert into hospital.dict_doctors (first_name, second_name, third_name, birth_date, is_active)
	values (p_first_name, p_second_name, p_third_name, p_birth_date, p_is_active);

	select id into v_doctor_id from hospital.dict_doctors
	where first_name = p_first_name
		and second_name = p_second_name
		and third_name = p_third_name;

	insert into hospital.map_prof (doctor_id, position_id, start_date)
	values (v_doctor_id, p_position_id, current_timestamp);
	return true;
	
	exception when others then 
		raise notice 'Ошибка добавления врача "% % %"', p_first_name, p_second_name,  p_third_name;
		return false;
end;
$function$
;

-- DROP FUNCTION hospital.add_patients(varchar, varchar, varchar, date, int8, bool);

CREATE OR REPLACE FUNCTION hospital.add_patients(p_first_name character varying, p_second_name character varying, p_third_name character varying, p_birth_date date, p_oms_name bigint, p_is_active boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare 
	v_patient_id int8;
	v_OMS_exists bool;
begin 
	select count(*)>=1 into v_OMS_exists 
	from hospital.dict_patients
	where OMS_name = p_OMS_name;

	if v_OMS_exists then 
		raise notice 'Полис ОМС % уже существует у другого пациента', p_OMS_name;
		return false;
	end if;

	insert into hospital.dict_patients (first_name, second_name, third_name, birth_date, OMS_name, is_active)
	values (p_first_name, p_second_name, p_third_name, p_birth_date, p_OMS_name, p_is_active);
	
	return true;

exception when others then 
	raise notice 'Ошибка добавления пациента %', p_OMS_name;
	return false;
end;
$function$
;