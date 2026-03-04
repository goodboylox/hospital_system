-- DROP SCHEMA hospital;

CREATE SCHEMA hospital AUTHORIZATION postgres;

-- DROP SEQUENCE hospital.dict_diseases_id_seq;

CREATE SEQUENCE hospital.dict_diseases_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.dict_diseases_type_id_seq;

CREATE SEQUENCE hospital.dict_diseases_type_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.dict_doctors_id_seq;

CREATE SEQUENCE hospital.dict_doctors_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.dict_patients_id_seq;

CREATE SEQUENCE hospital.dict_patients_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.dict_positions_id_seq;

CREATE SEQUENCE hospital.dict_positions_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.dict_symptoms_id_seq;

CREATE SEQUENCE hospital.dict_symptoms_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE hospital.map_patients2diseases_id_seq;

CREATE SEQUENCE hospital.map_patients2diseases_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;-- hospital.dict_diseases определение

-- Drop table

-- DROP TABLE hospital.dict_diseases;

CREATE TABLE hospital.dict_diseases (
	id bigserial NOT NULL,
	disease_name varchar(50) NOT NULL,
	dangerous varchar(50) NOT NULL,
	type_diseases text NOT NULL,
	description text NOT NULL,
	therapy_name text NOT NULL,
	is_active bool DEFAULT true NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_diseases_pkey PRIMARY KEY (id)
);


-- hospital.dict_diseases_type определение

-- Drop table

-- DROP TABLE hospital.dict_diseases_type;

CREATE TABLE hospital.dict_diseases_type (
	id bigserial NOT NULL,
	disease_type_name text NOT NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_diseases_type_pkey PRIMARY KEY (id)
);


-- hospital.dict_doctors определение

-- Drop table

-- DROP TABLE hospital.dict_doctors;

CREATE TABLE hospital.dict_doctors (
	id bigserial NOT NULL,
	first_name varchar(50) NOT NULL,
	second_name varchar(50) NOT NULL,
	third_name varchar(50) NOT NULL,
	birth_date date NULL,
	is_active bool DEFAULT true NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_doctors_pkey PRIMARY KEY (id)
);


-- hospital.dict_patients определение

-- Drop table

-- DROP TABLE hospital.dict_patients;

CREATE TABLE hospital.dict_patients (
	id bigserial NOT NULL,
	first_name varchar(50) NOT NULL,
	second_name varchar(50) NOT NULL,
	third_name varchar(50) NOT NULL,
	birth_date date NULL,
	registration_date date DEFAULT CURRENT_DATE NULL,
	oms_name int8 NOT NULL,
	is_active bool DEFAULT true NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_patients_pkey PRIMARY KEY (id)
);


-- hospital.dict_positions определение

-- Drop table

-- DROP TABLE hospital.dict_positions;

CREATE TABLE hospital.dict_positions (
	id bigserial NOT NULL,
	position_name varchar(100) NOT NULL,
	is_active bool DEFAULT true NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_positions_pkey PRIMARY KEY (id)
);


-- hospital.dict_symptoms определение

-- Drop table

-- DROP TABLE hospital.dict_symptoms;

CREATE TABLE hospital.dict_symptoms (
	id bigserial NOT NULL,
	symptom_name text NOT NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT dict_symptoms_pkey PRIMARY KEY (id)
);


-- hospital.map_patients2diseases определение

-- Drop table

-- DROP TABLE hospital.map_patients2diseases;

CREATE TABLE hospital.map_patients2diseases (
	id bigserial NOT NULL,
	patient_id int8 NOT NULL,
	disease_id int8 NOT NULL,
	doctor_id int8 NOT NULL,
	start_date timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	end_date timestamp DEFAULT '2399-12-31 00:00:00'::timestamp without time zone NULL,
	is_other_therapy bool DEFAULT true NULL,
	other_therapy text NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT map_patients2diseases_pkey PRIMARY KEY (id)
);


-- hospital.map_diseases2symptoms определение

-- Drop table

-- DROP TABLE hospital.map_diseases2symptoms;

CREATE TABLE hospital.map_diseases2symptoms (
	patients2diseases_id int8 NOT NULL,
	symptom_id int8 NOT NULL,
	is_active bool DEFAULT true NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT patients2diseases_id_pk PRIMARY KEY (patients2diseases_id, symptom_id),
	CONSTRAINT patients2diseases_id_unique FOREIGN KEY (patients2diseases_id) REFERENCES hospital.map_patients2diseases(id),
	CONSTRAINT symptom_id_unique FOREIGN KEY (symptom_id) REFERENCES hospital.dict_symptoms(id)
);


-- hospital.map_prof определение

-- Drop table

-- DROP TABLE hospital.map_prof;

CREATE TABLE hospital.map_prof (
	doctor_id int8 NOT NULL,
	position_id int8 NOT NULL,
	start_date timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	end_date timestamp DEFAULT '2399-12-31 00:00:00'::timestamp without time zone NULL,
	created_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	update_dttm timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	update_user varchar(50) DEFAULT 'system'::character varying NOT NULL,
	CONSTRAINT doctor_id_unique FOREIGN KEY (doctor_id) REFERENCES hospital.dict_doctors(id),
	CONSTRAINT position_id_unique FOREIGN KEY (position_id) REFERENCES hospital.dict_positions(id)
);