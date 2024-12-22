--procedure for admin
CREATE OR REPLACE PROCEDURE add_client(
    p_username VARCHAR, 
    p_password TEXT, 
    p_first_name VARCHAR DEFAULT 'Unknown', 
    p_last_name VARCHAR DEFAULT 'Unknown', 
    p_email VARCHAR DEFAULT 'example@example.com', 
    p_phone VARCHAR DEFAULT 'Unknown'
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    new_user_id INT;
    digit_count INT;
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Пользователь с именем % уже существует.', p_username;
    END IF;

    p_password_hash := crypt(p_password, gen_salt('bf', 8));

    SELECT LENGTH(REGEXP_REPLACE(p_password, '\D', '', 'g')) INTO digit_count;
    IF digit_count < 5 THEN
        RAISE EXCEPTION 'Пароль должен содержать не менее 5 цифр';
    END IF;

    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, 'client')
    RETURNING user_id INTO new_user_id;

    INSERT INTO clients (user_id, first_name, last_name, phone, email)
    VALUES (new_user_id, p_first_name, p_last_name, p_phone, p_email);
    
    RAISE NOTICE 'Клиент % успешно добавлен.', p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE update_client(
    p_username VARCHAR, 
    p_password TEXT DEFAULT NULL, 
    p_first_name VARCHAR DEFAULT NULL, 
    p_last_name VARCHAR DEFAULT NULL, 
    p_email VARCHAR DEFAULT NULL, 
    p_phone VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    IF p_password IS NOT NULL THEN
        p_password_hash := crypt(p_password, gen_salt('bf', 8));
    END IF;

    UPDATE users
    SET 
        password_hash = COALESCE(p_password_hash, password_hash)
    WHERE user_id = p_user_id;

    UPDATE clients
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone)
    WHERE user_id = p_user_id;

    RAISE NOTICE 'Данные клиента % обновлены.', p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_user(p_username VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    DELETE FROM appointments WHERE veterinarian_id = p_user_id;

    DELETE FROM clients WHERE user_id = p_user_id;

    DELETE FROM employees WHERE user_id = p_user_id;

    DELETE FROM users WHERE user_id = p_user_id;

    RAISE NOTICE 'Пользователь с логином % удален.', p_username;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_employee(
    p_username VARCHAR, 
    p_password TEXT, 
    p_first_name VARCHAR DEFAULT 'Unknown', 
    p_last_name VARCHAR DEFAULT 'Unknown', 
    p_position VARCHAR DEFAULT NULL 
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    new_user_id INT;
    digit_count INT;
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Пользователь с именем % уже существует.', p_username;
    END IF;

   IF p_first_name !~ '^[A-Za-zА-Яа-яЁё]+$' THEN
        RAISE EXCEPTION 'Имя должно содержать только буквы';
    END IF;

    IF p_last_name !~ '^[A-Za-zА-Яа-яЁё]+$' THEN
        RAISE EXCEPTION 'Фамилия должна содержать только буквы';
    END IF;

    p_password_hash := crypt(p_password, gen_salt('bf', 8));

    SELECT LENGTH(REGEXP_REPLACE(p_password, '\D', '', 'g')) INTO digit_count;
    IF digit_count < 5 THEN
        RAISE EXCEPTION 'Пароль должен содержать не менее 5 цифр';
    END IF;

    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, 'employee')
    RETURNING user_id INTO new_user_id;

    IF p_position IS NULL THEN
        RAISE EXCEPTION 'Должность должна быть указана для сотрудника';
    END IF;

    IF NOT p_position IN ('Ветеринарный терапевт', 'Ветеринарный хирург', 'Ветеринарный офтальмолог', 'Ветеринарный кардиолог') THEN
        RAISE EXCEPTION 'Недопустимая должность.';
    END IF;

    INSERT INTO employees (user_id, first_name, last_name, position, hire_date)
    VALUES (new_user_id, p_first_name, p_last_name, p_position, CURRENT_DATE);
    
    RAISE NOTICE 'Сотрудник % успешно добавлен.', p_username;
END;
$$;

CREATE OR REPLACE PROCEDURE update_employee(
    p_username VARCHAR, 
    p_password TEXT DEFAULT NULL, 
    p_first_name VARCHAR DEFAULT NULL, 
    p_last_name VARCHAR DEFAULT NULL, 
    p_position VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    IF p_password IS NOT NULL THEN
        p_password_hash := crypt(p_password, gen_salt('bf', 8));
    END IF;

    UPDATE users
    SET password_hash = COALESCE(p_password_hash, password_hash)
    WHERE user_id = p_user_id;

    IF p_position IS NOT NULL THEN
        IF NOT p_position IN ('Ветеринарный терапевт', 'Ветеринарный хирург', 'Ветеринарный офтальмолог', 'Ветеринарный кардиолог') THEN
            RAISE EXCEPTION 'Недопустимая должность.';
        END IF;

        UPDATE employees
        SET position = p_position
        WHERE user_id = p_user_id;
    END IF;

    IF p_first_name !~ '^[A-Za-zА-Яа-яЁё]+$' THEN
        RAISE EXCEPTION 'Имя должно содержать только буквы';
    END IF;

    IF p_last_name !~ '^[A-Za-zА-Яа-яЁё]+$' THEN
        RAISE EXCEPTION 'Фамилия должна содержать только буквы';
    END IF;
    UPDATE employees
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name)
    WHERE user_id = p_user_id;

    RAISE NOTICE 'Данные сотрудника % успешно обновлены.', p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_employee(p_username VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    DELETE FROM employees WHERE user_id = p_user_id;

    DELETE FROM users WHERE user_id = p_user_id;

    RAISE NOTICE 'Сотрудник с логином % удалён.', p_username;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_client(
    p_username VARCHAR, 
    p_password TEXT, 
    p_first_name VARCHAR DEFAULT 'Unknown', 
    p_last_name VARCHAR DEFAULT 'Unknown', 
    p_email VARCHAR DEFAULT 'example@example.com', 
    p_phone VARCHAR DEFAULT 'Unknown'
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    new_user_id INT;
    digit_count INT;
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Пользователь с именем % уже существует.', p_username;
    END IF;

    p_password_hash := crypt(p_password, gen_salt('bf', 8));

    SELECT LENGTH(REGEXP_REPLACE(p_password, '\D', '', 'g')) INTO digit_count;
    IF digit_count < 5 THEN
        RAISE EXCEPTION 'Пароль должен содержать не менее 5 цифр';
    END IF;

    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, 'client')
    RETURNING user_id INTO new_user_id;

    INSERT INTO clients (user_id, first_name, last_name, phone, email)
    VALUES (new_user_id, p_first_name, p_last_name, p_phone, p_email);
    
    RAISE NOTICE 'Клиент % успешно добавлен.', p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE update_client(
    p_username VARCHAR, 
    p_password TEXT DEFAULT NULL, 
    p_first_name VARCHAR DEFAULT NULL, 
    p_last_name VARCHAR DEFAULT NULL, 
    p_email VARCHAR DEFAULT NULL, 
    p_phone VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    p_password_hash TEXT;
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    IF p_password IS NOT NULL THEN
        p_password_hash := crypt(p_password, gen_salt('bf', 8));
    END IF;

    UPDATE users
    SET 
        password_hash = COALESCE(p_password_hash, password_hash)
    WHERE user_id = p_user_id;

    UPDATE clients
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone)
    WHERE user_id = p_user_id;

    RAISE NOTICE 'Данные клиента % обновлены.', p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_client(p_username VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    p_user_id INT;
BEGIN
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', p_username;
    END IF;

    DELETE FROM clients WHERE user_id = p_user_id;

    DELETE FROM users WHERE user_id = p_user_id;

    RAISE NOTICE 'Клиент с логином % удалён.', p_username;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_pet_for_admin( 
    p_pet_name VARCHAR,
    p_species VARCHAR,
    p_breed VARCHAR,
    p_birth_date DATE,
    p_username VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;
    valid_breeds TEXT[];
    current_date DATE := CURRENT_DATE;
BEGIN
    IF p_birth_date::TEXT !~ '^\d{4}-\d{2}-\d{2}$' THEN
        RAISE EXCEPTION 'Неверный формат даты рождения. Ожидается формат yyyy-mm-dd.';
    END IF;

    SELECT c.client_id INTO p_owner_id
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    WHERE u.username = p_username
    LIMIT 1;

    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с логином % не найден.', p_username;
    END IF;

    IF p_pet_name IS NULL OR LENGTH(TRIM(p_pet_name)) < 3 THEN
        RAISE EXCEPTION 'Имя питомца должно содержать минимум 3 символа.';
    END IF;

    IF NOT p_pet_name ~* '^[А-Яа-яA-Za-z ]+$' THEN
        RAISE EXCEPTION 'Имя питомца должно содержать только буквы.';
    END IF;

    IF p_birth_date > current_date THEN
        RAISE EXCEPTION 'Дата рождения не может быть в будущем.';
    ELSIF EXTRACT(YEAR FROM p_birth_date) < 1000 THEN
        RAISE EXCEPTION 'Дата рождения не может быть раньше 1000 года.';
    END IF;

    CASE p_species
        WHEN 'Собака' THEN valid_breeds := ARRAY['Лабрадор', 'Немецкая овчарка'];
        WHEN 'Кошка' THEN valid_breeds := ARRAY['Сиамская', 'Персидская', 'Британец'];
        WHEN 'Попугай' THEN valid_breeds := ARRAY['Ара', 'Жако'];
        WHEN 'Хомяк' THEN valid_breeds := ARRAY['Сирийский', 'Джунгарский'];
        WHEN 'Кролик' THEN valid_breeds := ARRAY['Мини-ломброза', 'Ангорский'];
        ELSE
            RAISE EXCEPTION 'Вид питомца должен быть одним из следующих: Собака, Кошка, Попугай, Хомяк, Кролик.';
    END CASE;

    IF p_breed IS NOT NULL AND array_position(valid_breeds, p_breed::text) IS NULL THEN
        RAISE EXCEPTION 'Порода % не подходит для вида питомца %.', p_breed, p_species;
    END IF;

    INSERT INTO pets (pet_name, species, breed, birth_date, owner_id)
    VALUES (p_pet_name, p_species, p_breed, p_birth_date, p_owner_id);

    RAISE NOTICE 'Питомец % успешно добавлен владельцу с логином %.', p_pet_name, p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE update_pet_for_admin(
    p_pet_name VARCHAR,
    p_username VARCHAR,
    p_new_pet_name VARCHAR DEFAULT NULL,
    p_new_species VARCHAR DEFAULT NULL,
    p_new_breed VARCHAR DEFAULT NULL,
    p_new_birth_date DATE DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;
    current_date DATE := CURRENT_DATE;
    valid_breeds TEXT[];
    current_species VARCHAR;
BEGIN
    IF p_new_birth_date IS NOT NULL AND p_new_birth_date::TEXT !~ '^\d{4}-\d{2}-\d{2}$' THEN
        RAISE EXCEPTION 'Неверный формат новой даты рождения. Ожидается формат yyyy-mm-dd.';
    END IF;

    SELECT c.client_id, p.species INTO p_owner_id, current_species
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    JOIN pets p ON p.owner_id = c.client_id
    WHERE u.username = p_username AND p.pet_name = p_pet_name
    LIMIT 1;

    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден для владельца с логином %.', p_pet_name, p_username;
    END IF;

    IF p_new_pet_name IS NOT NULL THEN
        IF LENGTH(TRIM(p_new_pet_name)) < 3 THEN
            RAISE EXCEPTION 'Новое имя питомца должно содержать минимум 3 символа.';
        END IF;

        IF NOT p_new_pet_name ~* '^[А-Яа-яA-Za-z ]+$' THEN
            RAISE EXCEPTION 'Новое имя питомца должно содержать только буквы.';
        END IF;
    END IF;

    IF p_new_birth_date IS NOT NULL THEN
        IF p_new_birth_date > current_date THEN
            RAISE EXCEPTION 'Дата рождения не может быть в будущем.';
        END IF;

        IF EXTRACT(YEAR FROM p_new_birth_date) < 1000 THEN
            RAISE EXCEPTION 'Дата рождения не может быть раньше 1000 года.';
        END IF;
    END IF;

    UPDATE pets
    SET 
        pet_name = COALESCE(p_new_pet_name, pet_name),
        species = COALESCE(p_new_species, species),
        breed = COALESCE(p_new_breed, breed),
        birth_date = COALESCE(p_new_birth_date, birth_date)
    WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    RAISE NOTICE 'Питомец % успешно обновлен владельцу с логином %.', p_pet_name, p_username;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_pet_for_admin(p_pet_name VARCHAR, p_username VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;
BEGIN
    SELECT c.client_id INTO p_owner_id
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    WHERE u.username = p_username
    LIMIT 1;

    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с логином % не найден.', p_username;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pets WHERE pet_name = p_pet_name AND owner_id = p_owner_id) THEN
        RAISE EXCEPTION 'Питомец с именем % не найден для владельца %.', p_pet_name, p_username;
    END IF;

    DELETE FROM pets WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    RAISE NOTICE 'Питомец с именем % успешно удален владельцу с логином %.', p_pet_name, p_username;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_service_for_admin(
    p_service_name VARCHAR,
    p_price NUMERIC,
    p_veterinarian_last_name VARCHAR,
    p_service_time TIMESTAMP,
    p_description TEXT DEFAULT NULL,
    p_available BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    vet_id INT;
    vet_position VARCHAR;
BEGIN
    SELECT employee_id, position INTO vet_id, vet_position
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM vet_service_mapping
        WHERE position = vet_position AND service_name = p_service_name
    ) THEN
        RAISE EXCEPTION 'Услуга % не может быть предоставлена данным ветеринаром, так как его должность (%), не соответствует данной услуге.', p_service_name, vet_position;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM services
        WHERE veterinarian_id = vet_id
        AND service_time = p_service_time
    ) THEN
        RAISE EXCEPTION 'Услуга с таким временем (%), уже существует для данного ветеринара.', p_service_time;
    END IF;

    IF p_service_time < CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата услуги должна быть не раньше сегодняшнего дня.';
    END IF;

    IF p_description IS NOT NULL AND p_description !~ '^[А-Яа-яA-Za-z ]+$' THEN
        RAISE EXCEPTION 'Описание услуги должно содержать только буквы и пробелы.';
    END IF;

    INSERT INTO services (service_name, price, veterinarian_id, veterinarian_first_name, veterinarian_last_name, service_time, available, description)
    VALUES (p_service_name, p_price, vet_id, (SELECT first_name FROM employees WHERE employee_id = vet_id), p_veterinarian_last_name, p_service_time, p_available, p_description);

    RAISE NOTICE 'Услуга % успешно добавлена для ветеринара %', p_service_name, p_veterinarian_last_name;
END;
$$;
CREATE OR REPLACE PROCEDURE update_service_for_admin(
    p_service_id INT,
    p_service_name VARCHAR,
    p_price NUMERIC,
    p_veterinarian_last_name VARCHAR,
    p_service_time TIMESTAMP,
    p_description TEXT DEFAULT NULL,
    p_available BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    vet_id INT;
BEGIN
    SELECT employee_id INTO vet_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM services
        WHERE veterinarian_id = vet_id
        AND service_time = p_service_time
        AND service_id != p_service_id
    ) THEN
        RAISE EXCEPTION 'Услуга с таким временем (%), уже существует для данного ветеринара.', p_service_time;
    END IF;

    IF p_description IS NOT NULL AND p_description !~ '^[А-Яа-яA-Za-z ]+$' THEN
        RAISE EXCEPTION 'Описание услуги должно содержать только буквы и пробелы.';
    END IF;

    UPDATE services
    SET service_name = p_service_name,
        price = p_price,
        veterinarian_id = vet_id,
        veterinarian_first_name = (SELECT first_name FROM employees WHERE employee_id = vet_id),
        veterinarian_last_name = p_veterinarian_last_name,
        service_time = p_service_time,
        available = p_available,
        description = p_description
    WHERE service_id = p_service_id;

    RAISE NOTICE 'Услуга с ID % успешно обновлена.', p_service_id;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_service_for_admin(
    p_service_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM services WHERE service_id = p_service_id;

    RAISE NOTICE 'Услуга с ID % успешно удалена.', p_service_id;
END;
$$;



drop table action_logs cascade;
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_appointment(
    p_pet_name VARCHAR,
    p_service_name VARCHAR,
    p_appointment_date TIMESTAMP,
    p_veterinarian_last_name VARCHAR,
    p_complaint TEXT,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_service_id INT;
    v_vet_id INT;
    v_vet_position VARCHAR;
    v_client_id INT;
    v_client_first_name VARCHAR;
    v_client_last_name VARCHAR;
BEGIN
    SELECT pet_id, owner_id 
    INTO v_pet_id, v_client_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с кличкой % не найден.', p_pet_name;
    END IF;

    SELECT first_name, last_name 
    INTO v_client_first_name, v_client_last_name
    FROM clients
    WHERE client_id = v_client_id;

    SELECT service_id 
    INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга с названием % не найдена.', p_service_name;
    END IF;

    SELECT employee_id, position 
    INTO v_vet_id, v_vet_position
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM vet_service_mapping
        WHERE position = v_vet_position
          AND service_name = p_service_name
    ) THEN
        RAISE EXCEPTION 'Услуга % не может быть предоставлена данным ветеринаром.', p_service_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM services
        WHERE service_id = v_service_id 
          AND service_time = p_appointment_date
    ) THEN
        RAISE EXCEPTION 'Услуга % недоступна на указанное время.', p_service_name;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM appointments
        WHERE appointment_date = p_appointment_date 
          AND veterinarian_id = v_vet_id
    ) THEN
        RAISE EXCEPTION 'На указанное время уже есть запись к ветеринару %.', p_veterinarian_last_name;
    END IF;

    INSERT INTO appointments (
        pet_id, service_id, appointment_date, complaint, veterinarian_id, notes
    )
    VALUES (
        v_pet_id, v_service_id, p_appointment_date, p_complaint, v_vet_id, p_notes
    );

    RAISE NOTICE 'Запись на прием успешно добавлена для питомца % клиента % %', 
                 p_pet_name, v_client_first_name, v_client_last_name;
END;
$$;

CREATE OR REPLACE PROCEDURE update_appointment(
    p_appointment_id INT,
    p_pet_name VARCHAR,
    p_service_name VARCHAR,
    p_appointment_date TIMESTAMP,
    p_veterinarian_last_name VARCHAR,
    p_complaint TEXT,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$  
DECLARE
    v_pet_id INT;
    v_service_id INT;
    v_vet_id INT;
    v_existing_appointment INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id
    ) THEN
        RAISE EXCEPTION 'Запись с ID % не найдена.', p_appointment_id;
    END IF;

    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с кличкой % не найден.', p_pet_name;
    END IF;

    SELECT service_id INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга с названием % не найдена.', p_service_name;
    END IF;

    SELECT employee_id INTO v_vet_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    SELECT appointment_id INTO v_existing_appointment
    FROM appointments
    WHERE service_id = v_service_id
      AND veterinarian_id = v_vet_id
      AND appointment_date = p_appointment_date
      AND appointment_id <> p_appointment_id;

    IF v_existing_appointment IS NOT NULL THEN
        RAISE EXCEPTION 'На выбранное время % уже существует запись на услугу % с данным ветеринаром.', p_appointment_date, p_service_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM services
        WHERE service_name = p_service_name
          AND service_time = p_appointment_date
          AND veterinarian_id = v_vet_id
    ) THEN
        RAISE EXCEPTION 'Услуга % не доступна на выбранное время для ветеринара %.', p_service_name, p_veterinarian_last_name;
    END IF;

    UPDATE appointments
    SET pet_id = v_pet_id,
        service_id = v_service_id,
        appointment_date = p_appointment_date,
        complaint = p_complaint,
        veterinarian_id = v_vet_id,
        notes = p_notes
    WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Запись с ID % успешно обновлена.', p_appointment_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_appointment(
    p_appointment_id INT
)
LANGUAGE plpgsql AS $$  
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id
    ) THEN
        RAISE EXCEPTION 'Запись на прием с ID % не найдена.', p_appointment_id;
    END IF;

    DELETE FROM appointments
    WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Запись на прием с ID % успешно удалена.', p_appointment_id;
END;
$$;
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_diagnosis(
    p_pet_name TEXT,               -- Имя питомца
    p_veterinarian_last_name TEXT,  -- Фамилия ветеринара
    p_diagnosis_text TEXT,          -- Текст диагноза
    p_notes TEXT DEFAULT NULL       -- Дополнительные заметки
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Проверка существования ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    -- Проверка, что ветеринар связан с услугой для данного питомца
    IF NOT EXISTS (
        SELECT 1
        FROM appointments
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        RAISE EXCEPTION 'Ветеринар % не может добавить диагноз для питомца %.', p_veterinarian_last_name, p_pet_name;
    END IF;

    -- Добавление диагноза
    INSERT INTO diagnoses (pet_id, veterinarian_id, diagnosis_text, notes)
    VALUES (v_pet_id, v_veterinarian_id, p_diagnosis_text, p_notes);

    RAISE NOTICE 'Диагноз успешно добавлен для питомца %.', p_pet_name;

END $$;

CREATE OR REPLACE PROCEDURE update_diagnosis(
    p_pet_name TEXT,               -- Имя питомца
    p_veterinarian_last_name TEXT,  -- Фамилия ветеринара
    p_diagnosis_text TEXT,          -- Текст диагноза
    p_notes TEXT DEFAULT NULL       -- Дополнительные заметки
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Получаем идентификатор ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    -- Проверка, что этот ветеринар имеет диагноз для питомца
    IF NOT EXISTS (
        SELECT 1
        FROM diagnoses
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        RAISE EXCEPTION 'Ветеринар % не может обновить диагноз для питомца %.', p_veterinarian_last_name, p_pet_name;
    END IF;

    -- Обновление диагноза
    UPDATE diagnoses
    SET diagnosis_text = p_diagnosis_text, 
        notes = COALESCE(p_notes, notes)
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id;

    RAISE NOTICE 'Диагноз для питомца % успешно обновлен.', p_pet_name;

END $$;


CREATE OR REPLACE PROCEDURE delete_diagnosis(
    p_pet_name TEXT,               -- Имя питомца
    p_veterinarian_last_name TEXT  -- Фамилия ветеринара
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Получаем идентификатор ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    -- Проверка, что этот ветеринар имеет диагноз для питомца
    IF NOT EXISTS (
        SELECT 1
        FROM diagnoses
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        RAISE EXCEPTION 'Ветеринар % не может удалить диагноз для питомца %.', p_veterinarian_last_name, p_pet_name;
    END IF;

    -- Удаление диагноза
    DELETE FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id;

    RAISE NOTICE 'Диагноз для питомца % успешно удален.', p_pet_name;

END $$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_review_for_admin(
    p_client_name VARCHAR,              -- Имя клиента
    p_service_name VARCHAR,             -- Название услуги
    p_veterinarian_last_name VARCHAR,   -- Фамилия ветеринара
    p_rating INT,                       -- Оценка
    p_review_text TEXT,                 -- Текст отзыва
    p_response_text TEXT DEFAULT NULL   -- Ответ (если есть)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_client_id INT;
    v_service_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получение ID клиента
    SELECT client_id INTO v_client_id
    FROM clients
    WHERE CONCAT(first_name, ' ', last_name) = p_client_name
    LIMIT 1;

    IF v_client_id IS NULL THEN
        RAISE EXCEPTION 'Клиент с именем % не найден.', p_client_name;
    END IF;

    -- Получение ID услуги
    SELECT service_id INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга % не найдена.', p_service_name;
    END IF;

    -- Получение ID ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    -- Вставка отзыва
    INSERT INTO reviews (
        client_id, service_id, rating, review_text, response_text
    ) VALUES (
        v_client_id, v_service_id, p_rating, p_review_text, p_response_text
    );

    RAISE NOTICE 'Отзыв успешно добавлен для клиента % по услуге % с участием ветеринара %.',
        p_client_name, p_service_name, p_veterinarian_last_name;
END;
$$;


CREATE OR REPLACE PROCEDURE update_review_for_admin(
    p_review_id INT,                   -- ID отзыва
    p_rating INT,                       -- Оценка
    p_review_text TEXT,                 -- Текст отзыва
    p_veterinarian_last_name VARCHAR,   -- Фамилия ветеринара
    p_response_text TEXT DEFAULT NULL   -- Ответ
)
LANGUAGE plpgsql AS $$
DECLARE
    v_veterinarian_id INT;
BEGIN
    -- Проверка существования отзыва
    IF NOT EXISTS (SELECT 1 FROM reviews WHERE review_id = p_review_id) THEN
        RAISE EXCEPTION 'Отзыв с ID % не найден.', p_review_id;
    END IF;

    -- Обновление отзыва
    UPDATE reviews
    SET rating = p_rating, review_text = p_review_text, response_text = p_response_text
    WHERE review_id = p_review_id;

    -- Если указана фамилия ветеринара, проверим ее
    IF p_veterinarian_last_name IS NOT NULL THEN
        -- Получение ID ветеринара
        SELECT employee_id INTO v_veterinarian_id
        FROM employees
        WHERE last_name = p_veterinarian_last_name
        LIMIT 1;

        IF v_veterinarian_id IS NULL THEN
            RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
        END IF;
    END IF;

    RAISE NOTICE 'Отзыв с ID % обновлен.', p_review_id;
END;
$$;


CREATE OR REPLACE PROCEDURE delete_review_for_admin(
    p_review_id INT  -- ID отзыва для удаления
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Проверяем, существует ли отзыв с таким ID
    IF NOT EXISTS (SELECT 1 FROM reviews WHERE review_id = p_review_id) THEN
        RAISE EXCEPTION 'Отзыв с ID % не найден.', p_review_id;
    END IF;

    -- Удаление отзыва
    DELETE FROM reviews WHERE review_id = p_review_id;

    -- Уведомление об успешном удалении
    RAISE NOTICE 'Отзыв с ID % успешно удален.', p_review_id;
END;
$$;
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_prescription_by_pet_name(
    p_pet_name VARCHAR,              -- Имя питомца
    p_veterinarian_name VARCHAR,     -- Имя и фамилия ветеринара
    p_medication_name VARCHAR,       -- Название лекарства
    p_dosage VARCHAR,                -- Дозировка
    p_administration_method VARCHAR, -- Способ применения
    p_treatment_duration VARCHAR,    -- Продолжительность лечения
    p_notes TEXT DEFAULT NULL        -- Примечания
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_diagnosis_id INT;
BEGIN
    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Получение ID ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE CONCAT(first_name, ' ', last_name) = p_veterinarian_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с именем % не найден.', p_veterinarian_name;
    END IF;

    -- Проверка наличия диагноза
    SELECT diagnosis_id INTO v_diagnosis_id
    FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ORDER BY diagnosis_date DESC
    LIMIT 1;

    IF v_diagnosis_id IS NULL THEN
        RAISE EXCEPTION 'Диагноз для питомца % не найден.', p_pet_name;
    END IF;

    -- Вставка рецепта
    INSERT INTO prescriptions (
        pet_id, veterinarian_id, diagnosis_id, prescription_date, 
        medication_name, dosage, administration_method, 
        treatment_duration, notes
    ) VALUES (
        v_pet_id, v_veterinarian_id, v_diagnosis_id, NOW(), 
        p_medication_name, p_dosage, p_administration_method, 
        p_treatment_duration, p_notes
    );

    RAISE NOTICE 'Рецепт для питомца % успешно добавлен.', p_pet_name;
END;
$$;


CREATE OR REPLACE PROCEDURE update_prescription_by_pet_name(
    p_pet_name VARCHAR,            
    p_veterinarian_name VARCHAR,  
    p_medication_name VARCHAR,    
    p_new_dosage VARCHAR,         
    p_new_administration_method VARCHAR, 
    p_new_treatment_duration VARCHAR,    
    p_new_notes TEXT DEFAULT NULL  
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_prescription_id INT;
BEGIN
    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Получение ID ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE CONCAT(first_name, ' ', last_name) = p_veterinarian_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с именем % не найден.', p_veterinarian_name;
    END IF;

    -- Получение ID рецепта
    SELECT prescription_id INTO v_prescription_id
    FROM prescriptions
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id 
          AND medication_name = p_medication_name
    ORDER BY prescription_date DESC
    LIMIT 1;

    IF v_prescription_id IS NULL THEN
        RAISE EXCEPTION 'Рецепт для питомца % не найден.', p_pet_name;
    END IF;

    -- Обновление рецепта
    UPDATE prescriptions
    SET 
        dosage = p_new_dosage,
        administration_method = p_new_administration_method,
        treatment_duration = p_new_treatment_duration,
        notes = p_new_notes
    WHERE prescription_id = v_prescription_id;

    RAISE NOTICE 'Рецепт для питомца % успешно обновлен.', p_pet_name;
END;
$$;


CREATE OR REPLACE PROCEDURE delete_prescription_by_pet_name(
    p_pet_name VARCHAR,           
    p_veterinarian_name VARCHAR, 
    p_medication_name VARCHAR    
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_prescription_id INT;
BEGIN
    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Получение ID ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE CONCAT(first_name, ' ', last_name) = p_veterinarian_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с именем % не найден.', p_veterinarian_name;
    END IF;

    -- Получение ID рецепта
    SELECT prescription_id INTO v_prescription_id
    FROM prescriptions
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id 
          AND medication_name = p_medication_name
    ORDER BY prescription_date DESC
    LIMIT 1;

    IF v_prescription_id IS NULL THEN
        RAISE EXCEPTION 'Рецепт для питомца % не найден.', p_pet_name;
    END IF;

    -- Удаление рецепта
    DELETE FROM prescriptions
    WHERE prescription_id = v_prescription_id;

    RAISE NOTICE 'Рецепт для питомца % успешно удален.', p_pet_name;
END;
$$;
-------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE book_appointment_for_admin(
    p_pet_name VARCHAR,               -- Имя питомца
    p_service_name VARCHAR,           -- Название услуги
    p_appointment_date TIMESTAMP,     -- Дата и время приема
    p_username VARCHAR,               -- Логин владельца питомца
    p_complaint TEXT DEFAULT NULL,    -- Жалоба (опционально)
    p_veterinarian_last_name VARCHAR DEFAULT NULL,  -- Фамилия ветеринара (опционально)
    p_veterinarian_id INT DEFAULT NULL  -- ID ветеринара (опционально)
)
LANGUAGE plpgsql AS $$
DECLARE
    p_pet_id INT;
    p_service_id INT;
    p_owner_id INT;
    p_veterinarian_id_final INT;
BEGIN
    -- Получение данных питомца
    SELECT pet_id, owner_id INTO p_pet_id, p_owner_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    -- Проверка владельца
    SELECT client_id INTO p_owner_id
    FROM clients
    JOIN users u ON clients.user_id = u.user_id
    WHERE u.username = p_username;

    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с логином % не найден.', p_username;
    END IF;

    -- Получение услуги
    SELECT service_id INTO p_service_id
    FROM services
    WHERE service_name = p_service_name;

    -- Проверка услуги
    IF p_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга % не найдена.', p_service_name;
    END IF;

    -- Назначение ветеринара
    IF p_veterinarian_last_name IS NOT NULL THEN
        SELECT employee_id INTO p_veterinarian_id_final
        FROM employees
        WHERE last_name = p_veterinarian_last_name;

        IF p_veterinarian_id_final IS NULL THEN
            RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
        END IF;
    ELSE
        SELECT veterinarian_id INTO p_veterinarian_id_final
        FROM services
        WHERE service_id = p_service_id;
    END IF;

    -- Проверка на занятость времени для выбранного ветеринара
    IF EXISTS (
        SELECT 1
        FROM appointments
        WHERE appointment_date = p_appointment_date
        AND veterinarian_id = p_veterinarian_id_final
    ) THEN
        RAISE EXCEPTION 'Время % уже занято для этого ветеринара. Выберите другое.', p_appointment_date;
    END IF;

    -- Запись на прием
    INSERT INTO appointments (pet_id, service_id, appointment_date, complaint, veterinarian_id)
    VALUES (p_pet_id, p_service_id, p_appointment_date, p_complaint, p_veterinarian_id_final);

    RAISE NOTICE 'Запись на прием успешно добавлена.';
END;
$$;


CREATE OR REPLACE PROCEDURE update_appointment_for_admin(
    p_appointment_id INT,             -- ID записи на прием
    p_new_service_name VARCHAR DEFAULT NULL, -- Новое название услуги
    p_new_appointment_date TIMESTAMP DEFAULT NULL, -- Новая дата записи
    p_new_complaint TEXT DEFAULT NULL,   -- Новая жалоба
    p_new_vet_last_name VARCHAR DEFAULT NULL -- Новая фамилия ветеринара
)
LANGUAGE plpgsql AS $$
DECLARE
    p_new_service_id INT;
    p_new_vet_id INT;
BEGIN
    -- Проверка существования записи
    IF NOT EXISTS (SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id) THEN
        RAISE EXCEPTION 'Запись на прием с ID % не найдена.', p_appointment_id;
    END IF;

    -- Если указана новая дата, проверяем на занятость времени для выбранного ветеринара
    IF p_new_appointment_date IS NOT NULL THEN
        -- Получение ветеринара, если его фамилия изменена
        IF p_new_vet_last_name IS NOT NULL THEN
            SELECT employee_id INTO p_new_vet_id
            FROM employees
            WHERE last_name = p_new_vet_last_name;

            IF p_new_vet_id IS NULL THEN
                RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_new_vet_last_name;
            END IF;
        ELSE
            SELECT veterinarian_id INTO p_new_vet_id
            FROM appointments
            WHERE appointment_id = p_appointment_id;
        END IF;

        -- Проверка занятости времени для нового ветеринара
        IF EXISTS (
            SELECT 1 
            FROM appointments 
            WHERE appointment_date = p_new_appointment_date
            AND veterinarian_id = p_new_vet_id
            AND appointment_id <> p_appointment_id  -- Исключаем текущую запись
        ) THEN
            RAISE EXCEPTION 'Время % уже занято для этого ветеринара. Выберите другое.', p_new_appointment_date;
        END IF;
    END IF;

    -- Обновление услуги, если она указана
    IF p_new_service_name IS NOT NULL THEN
        SELECT service_id INTO p_new_service_id
        FROM services
        WHERE service_name = p_new_service_name;

        IF p_new_service_id IS NULL THEN
            RAISE EXCEPTION 'Услуга % не найдена.', p_new_service_name;
        END IF;
    END IF;

    -- Обновление записи
    UPDATE appointments
    SET 
        service_id = COALESCE(p_new_service_id, service_id),
        appointment_date = COALESCE(p_new_appointment_date, appointment_date),
        complaint = COALESCE(p_new_complaint, complaint),
        veterinarian_id = COALESCE(p_new_vet_id, veterinarian_id)
    WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Запись на прием с ID % успешно обновлена.', p_appointment_id;
END;
$$;






CREATE OR REPLACE PROCEDURE delete_appointment_for_admin(
    p_appointment_id INT -- ID записи на прием для удаления
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Проверка существования записи
    IF NOT EXISTS (SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id) THEN
        RAISE EXCEPTION 'Запись на прием с ID % не найдена.', p_appointment_id;
    END IF;

    -- Удаление записи
    DELETE FROM appointments WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Запись на прием с ID % успешно удалена.', p_appointment_id;
END;
$$;
