--procedure for employee
CREATE OR REPLACE PROCEDURE update_employee_for_employee(
    p_first_name VARCHAR DEFAULT NULL,   -- Новое имя (если нужно изменить)
    p_last_name VARCHAR DEFAULT NULL,    -- Новая фамилия (если нужно изменить)
    p_position VARCHAR DEFAULT NULL      -- Новая должность (если нужно изменить)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_user_id INT;
    v_employee_id INT;
BEGIN
    -- Получаем ID пользователя (сотрудника), выполняющего запрос
    SELECT u.user_id INTO v_user_id
    FROM users u
    WHERE u.username = CURRENT_USER;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Пользователь с логином % не найден.', CURRENT_USER;
    END IF;

    -- Получаем ID сотрудника, соответствующего этому пользователю
    SELECT e.employee_id INTO v_employee_id
    FROM employees e
    WHERE e.user_id = v_user_id;

    IF v_employee_id IS NULL THEN
        RAISE EXCEPTION 'Сотрудник с таким пользователем не найден.';
    END IF;

    -- Проверка на корректность должности
    IF p_position IS NOT NULL AND NOT TRIM(REGEXP_REPLACE(p_position, '\s+', ' ', 'g')) IN ('Ветеринарный терапевт', 'Ветеринарный хирург', 'Ветеринарный офтальмолог', 'Ветеринарный кардиолог') THEN
        RAISE EXCEPTION 'Недопустимая должность. Должности должны быть одной из следующих: Ветеринарный терапевт, Ветеринарный хирург, Ветеринарный офтальмолог, Ветеринарный кардиолог';
    END IF;

    -- Обновляем данные сотрудника
    UPDATE employees
    SET
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        position = COALESCE(p_position, position)
    WHERE employee_id = v_employee_id;

    RAISE NOTICE 'Данные сотрудника успешно обновлены.';
END;
$$;
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_service_for_employee(
    p_service_name VARCHAR,        -- Имя услуги
    p_price NUMERIC,               -- Цена услуги
    p_service_time TIMESTAMP,      -- Время услуги
    p_description TEXT DEFAULT NULL, -- Описание услуги
    p_available BOOLEAN DEFAULT TRUE -- Доступность услуги
)
LANGUAGE plpgsql AS $$
DECLARE
    vet_id INT;
    vet_position VARCHAR;
BEGIN
    -- Получаем должность сотрудника
    SELECT position INTO vet_position
    FROM employees
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER);

    -- Проверка, что сотрудник является "Ветеринарным терапевтом"
    IF vet_position != 'Ветеринарный терапевт' THEN
        RAISE EXCEPTION 'Вы не можете добавить эту услугу, так как не являетесь ветеринаром терапевтом.';
    END IF;

    -- Получаем ID ветеринара (если сотрудник является терапевтом)
    SELECT employee_id INTO vet_id
    FROM employees
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER);

    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с логином % не найден.', CURRENT_USER;
    END IF;

    -- Проверка соответствия должности ветеринара услуге
    IF NOT EXISTS (
        SELECT 1
        FROM vet_service_mapping
        WHERE position = vet_position AND service_name = p_service_name
    ) THEN
        RAISE EXCEPTION 'Услуга % не может быть предоставлена данным ветеринаром, так как его должность (%), не соответствует данной услуге.', p_service_name, vet_position;
    END IF;

    -- Вставка услуги
    INSERT INTO services (service_name, price, veterinarian_id, veterinarian_first_name, veterinarian_last_name, service_time, available, description)
    VALUES (p_service_name, p_price, vet_id, (SELECT first_name FROM employees WHERE employee_id = vet_id), 
            (SELECT last_name FROM employees WHERE employee_id = vet_id), p_service_time, p_available, p_description);

    RAISE NOTICE 'Услуга % успешно добавлена для ветеринара %', p_service_name, (SELECT last_name FROM employees WHERE employee_id = vet_id);
END;
$$;


CREATE OR REPLACE PROCEDURE update_service_for_employee(
    p_service_id INT,              -- ID услуги
    p_service_name VARCHAR,        -- Имя услуги
    p_price NUMERIC,               -- Цена услуги
    p_service_time TIMESTAMP,      -- Время услуги
    p_description TEXT DEFAULT NULL, -- Описание услуги
    p_available BOOLEAN DEFAULT TRUE -- Доступность услуги
)
LANGUAGE plpgsql AS $$
DECLARE
    vet_id INT;
    vet_position VARCHAR;
BEGIN
    -- Получаем должность сотрудника
    SELECT position INTO vet_position
    FROM employees
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER);

    -- Проверка, что сотрудник является "Ветеринарным терапевтом"
    IF vet_position != 'Ветеринарный терапевт' THEN
        RAISE EXCEPTION 'Вы не можете изменить эту услугу, так как не являетесь ветеринаром терапевтом.';
    END IF;

    -- Получаем ID ветеринара
    SELECT employee_id INTO vet_id
    FROM employees
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER);

    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с логином % не найден.', CURRENT_USER;
    END IF;

    -- Проверка соответствия должности ветеринара услуге
    IF NOT EXISTS (
        SELECT 1
        FROM vet_service_mapping
        WHERE position = vet_position AND service_name = p_service_name
    ) THEN
        RAISE EXCEPTION 'Услуга % не может быть предоставлена данным ветеринаром, так как его должность (%), не соответствует данной услуге.', p_service_name, vet_position;
    END IF;

    -- Обновление услуги
    UPDATE services
    SET service_name = p_service_name,
        price = p_price,
        service_time = p_service_time,
        available = p_available,
        description = p_description
    WHERE service_id = p_service_id AND veterinarian_id = vet_id;

    RAISE NOTICE 'Услуга с ID % успешно обновлена для ветеринара %', p_service_id, (SELECT last_name FROM employees WHERE employee_id = vet_id);
END;
$$;



CREATE OR REPLACE PROCEDURE delete_service_for_employee(
    p_service_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_employee_id INT;
BEGIN
    -- Получаем ID текущего пользователя
    SELECT employee_id 
    INTO v_employee_id
    FROM employees e
    JOIN users u ON e.user_id = u.user_id
    WHERE u.username = CURRENT_USER;

    -- Удаляем услугу, если она принадлежит текущему сотруднику
    DELETE FROM services 
    WHERE service_id = p_service_id 
      AND veterinarian_id = v_employee_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Услуга с ID % не найдена или вы не являетесь её исполнителем.', p_service_id;
    END IF;

    RAISE NOTICE 'Услуга с ID % успешно удалена.', p_service_id;
END;
$$;
--------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_own_diagnosis_for_employee(
    p_pet_name TEXT,               -- Имя питомца
    p_diagnosis_text TEXT,         -- Текст диагноза
    p_notes TEXT DEFAULT NULL      -- Примечания
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получаем ID питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Получаем идентификатор ветеринара (сотрудник, который выполняет процедуру)
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER); -- Связываем с текущим пользователем

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с логином % не найден.', CURRENT_USER;
    END IF;

    -- Проверка, что ветеринар действительно принимал этого питомца
    IF NOT EXISTS (
        SELECT 1
        FROM appointments
        WHERE pet_id = v_pet_id 
        AND veterinarian_id = v_veterinarian_id
    ) THEN
        RAISE EXCEPTION 'Ветеринар % не может добавить диагноз для питомца %: он не принимал этого питомца.', 
                         (SELECT last_name FROM employees WHERE employee_id = v_veterinarian_id), p_pet_name;
    END IF;

    -- Добавление диагноза
    INSERT INTO diagnoses (pet_id, veterinarian_id, diagnosis_text, notes)
    VALUES (v_pet_id, v_veterinarian_id, p_diagnosis_text, p_notes);

    RAISE NOTICE 'Диагноз успешно добавлен для питомца %.', p_pet_name;
END $$;
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE update_own_diagnosis_for_employee(
    p_pet_name TEXT,               -- Имя питомца
    p_diagnosis_text TEXT,         -- Новый текст диагноза
    p_notes TEXT DEFAULT NULL      -- Дополнительные заметки
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_diagnosis_id INT;
BEGIN
    -- Получаем ID питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Получаем ID ветеринара (поставившего диагноз)
    SELECT employee_id INTO v_veterinarian_id
    FROM employees 
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER)
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар не найден для текущего пользователя.';
    END IF;

    -- Получаем ID диагноза для этого питомца и ветеринара
    SELECT diagnosis_id INTO v_diagnosis_id 
    FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    LIMIT 1;

    IF v_diagnosis_id IS NULL THEN
        RAISE EXCEPTION 'Диагноз для питомца % не найден или он был поставлен другим ветеринаром.', p_pet_name;
    END IF;

    -- Обновление диагноза
    UPDATE diagnoses
    SET diagnosis_text = p_diagnosis_text, 
        notes = COALESCE(p_notes, notes)
    WHERE diagnosis_id = v_diagnosis_id;

    RAISE NOTICE 'Диагноз для питомца % успешно обновлен.', p_pet_name;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_own_diagnosis_for_employee(
    p_pet_name TEXT                -- Имя питомца
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_diagnosis_id INT;
BEGIN
    -- Получаем ID питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец % не найден.', p_pet_name;
    END IF;

    -- Получаем ID ветеринара (поставившего диагноз)
    SELECT employee_id INTO v_veterinarian_id
    FROM employees 
    WHERE user_id = (SELECT user_id FROM users WHERE username = CURRENT_USER)
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар не найден для текущего пользователя.';
    END IF;

    -- Получаем ID диагноза для этого питомца и ветеринара
    SELECT diagnosis_id INTO v_diagnosis_id 
    FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    LIMIT 1;

    IF v_diagnosis_id IS NULL THEN
        RAISE EXCEPTION 'Диагноз для питомца % не найден или он был поставлен другим ветеринаром.', p_pet_name;
    END IF;

    -- Удаление диагноза
    DELETE FROM diagnoses
    WHERE diagnosis_id = v_diagnosis_id;

    RAISE NOTICE 'Диагноз для питомца % успешно удален.', p_pet_name;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_own_prescription(
    p_pet_name VARCHAR,              
    p_medication_name VARCHAR,       
    p_dosage VARCHAR,                
    p_administration_method VARCHAR, 
    p_treatment_duration VARCHAR,    
    p_notes TEXT DEFAULT NULL        
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_diagnosis_id INT;
BEGIN
    -- Проверка питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Проверка ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    JOIN users u ON employees.user_id = u.user_id
    WHERE u.username = CURRENT_USER
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с текущим логином не найден.';
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


CREATE OR REPLACE PROCEDURE update_own_prescription(
    p_pet_name VARCHAR,            
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
    -- Проверка питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Проверка ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    JOIN users u ON employees.user_id = u.user_id
    WHERE u.username = CURRENT_USER
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с текущим логином не найден.';
    END IF;

    -- Проверка рецепта
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


CREATE OR REPLACE PROCEDURE delete_own_prescription(
    p_pet_name VARCHAR,           
    p_medication_name VARCHAR    
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pet_id INT;
    v_veterinarian_id INT;
    v_prescription_id INT;
BEGIN
    -- Проверка питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Проверка ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    JOIN users u ON employees.user_id = u.user_id
    WHERE u.username = CURRENT_USER
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с текущим логином не найден.';
    END IF;

    -- Проверка рецепта
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
-------------------------------------------------------------------------------------------------------------------------------------------------------
