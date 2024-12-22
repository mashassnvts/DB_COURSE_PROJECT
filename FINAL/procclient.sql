--procedure for client
CREATE OR REPLACE PROCEDURE add_pet(
    p_pet_name VARCHAR,            -- Имя питомца
    p_species VARCHAR,             -- Вид питомца
    p_breed VARCHAR DEFAULT NULL,  -- Порода питомца (по умолчанию NULL)
    p_birth_date DATE DEFAULT NULL -- Дата рождения питомца (по умолчанию NULL)
)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;  -- Переменная для хранения ID владельца
    valid_breeds TEXT[]; -- Массив допустимых пород для указанного вида питомца
    current_date DATE := CURRENT_DATE;  -- Текущая дата
BEGIN
    -- Получаем ID владельца через представление client_view, которое фильтрует данные по текущему пользователю
    SELECT client_id INTO p_owner_id
    FROM client_view
    LIMIT 1;

    -- Проверка на существование владельца
    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с именем % не найден.', CURRENT_USER;
    END IF;

    -- Валидация имени питомца
    IF p_pet_name IS NULL OR LENGTH(TRIM(p_pet_name)) < 3 THEN
        RAISE EXCEPTION 'Имя питомца должно содержать минимум 3 символа.';
    END IF;

    IF NOT p_pet_name ~* '^[А-Яа-яA-Za-z ]+$' THEN
        RAISE EXCEPTION 'Имя питомца должно содержать только буквы.';
    END IF;

    -- Валидация вида питомца и пород
    IF p_species = 'Собака' THEN
        valid_breeds := ARRAY['Лабрадор', 'Немецкая овчарка'];
    ELSIF p_species = 'Кошка' THEN
        valid_breeds := ARRAY['Сиамская', 'Персидская', 'Британец'];
    ELSIF p_species = 'Попугай' THEN
        valid_breeds := ARRAY['Ара', 'Жако'];
    ELSIF p_species = 'Хомяк' THEN
        valid_breeds := ARRAY['Сирийский', 'Джунгарский'];
    ELSIF p_species = 'Кролик' THEN
        valid_breeds := ARRAY['Мини-ломброза', 'Ангорский'];
    ELSE
        RAISE EXCEPTION 'Вид питомца должен быть одним из следующих: Собака, Кошка, Попугай, Хомяк, Кролик.';
    END IF;

    -- Проверка на допустимость породы для выбранного вида
    IF p_breed IS NOT NULL AND array_position(valid_breeds, p_breed::text) IS NULL THEN
        RAISE EXCEPTION 'Порода % не подходит для вида питомца %.', p_breed, p_species;
    END IF;

    -- Добавление питомца
    INSERT INTO pets (pet_name, species, breed, birth_date, owner_id)
    VALUES (p_pet_name, p_species, p_breed, p_birth_date, p_owner_id);

    RAISE NOTICE 'Питомец % успешно добавлен.', p_pet_name;
END;
$$;




CREATE OR REPLACE PROCEDURE update_pet_for_client(
    p_pet_name VARCHAR,               -- Имя питомца, которое нужно обновить
    p_new_pet_name VARCHAR DEFAULT NULL, -- Новое имя питомца
    p_new_species VARCHAR DEFAULT NULL,  -- Новый вид питомца
    p_new_breed VARCHAR DEFAULT NULL,    -- Новая порода питомца
    p_new_birth_date DATE DEFAULT NULL   -- Новая дата рождения питомца
)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;  -- Переменная для хранения ID владельца
    valid_breeds TEXT[];  -- Массив допустимых пород для указанного вида питомца
    current_date DATE := CURRENT_DATE;  -- Текущая дата
    current_species VARCHAR;  -- Текущий вид питомца
    current_breed VARCHAR;    -- Текущая порода питомца
BEGIN
    -- Получаем ID владельца питомца через представление client_pets
    SELECT owner_id, species, breed INTO p_owner_id, current_species, current_breed
    FROM client_pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    -- Проверка на существование питомца у текущего владельца
    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден для владельца %.', p_pet_name, CURRENT_USER;
    END IF;

    -- Валидация новых значений (если они не NULL)
    IF p_new_pet_name IS NOT NULL THEN
        IF LENGTH(TRIM(p_new_pet_name)) < 3 THEN
            RAISE EXCEPTION 'Новое имя питомца должно содержать минимум 3 символа.';
        END IF;

        IF NOT p_new_pet_name ~* '^[А-Яа-яA-Za-z ]+$' THEN
            RAISE EXCEPTION 'Новое имя питомца должно содержать только буквы.';
        END IF;
    END IF;

    IF p_new_species IS NOT NULL THEN
        -- Валидация вида питомца
        IF p_new_species NOT IN ('Собака', 'Кошка', 'Попугай', 'Хомяк', 'Кролик') THEN
            RAISE EXCEPTION 'Вид питомца должен быть одним из следующих: Собака, Кошка, Попугай, Хомяк, Кролик.';
        END IF;

        -- Проверка на изменение вида питомца
        IF p_new_species <> current_species THEN
            RAISE EXCEPTION 'Невозможно изменить вид питомца с % на %.', current_species, p_new_species;
        END IF;
    END IF;

    -- Валидация породы питомца
    IF p_new_breed IS NOT NULL THEN
        -- Валидация пород в зависимости от вида питомца
        IF p_new_species = 'Собака' THEN
            valid_breeds := ARRAY['Лабрадор', 'Немецкая овчарка'];
        ELSIF p_new_species = 'Кошка' THEN
            valid_breeds := ARRAY['Сиамская', 'Персидская', 'Британец'];
        ELSIF p_new_species = 'Попугай' THEN
            valid_breeds := ARRAY['Ара', 'Жако'];
        ELSIF p_new_species = 'Хомяк' THEN
            valid_breeds := ARRAY['Сирийский', 'Джунгарский'];
        ELSIF p_new_species = 'Кролик' THEN
            valid_breeds := ARRAY['Мини-ломброза', 'Ангорский'];
        ELSE
            RAISE EXCEPTION 'Вид питомца должен быть одним из следующих: Собака, Кошка, Попугай, Хомяк, Кролик.';
        END IF;

        -- Проверка на допустимость породы для выбранного вида
        IF array_position(valid_breeds, p_new_breed::text) IS NULL THEN
            RAISE EXCEPTION 'Порода % не подходит для вида питомца %.', p_new_breed, p_new_species;
        END IF;
    END IF;

    -- Валидация даты рождения
    IF p_new_birth_date IS NOT NULL THEN
        -- Проверка, что дата не в будущем
        IF p_new_birth_date > current_date THEN
            RAISE EXCEPTION 'Дата рождения не может быть в будущем.';
        END IF;

        -- Проверка, что дата не раньше 1000 года
        IF EXTRACT(YEAR FROM p_new_birth_date) < 1000 THEN
            RAISE EXCEPTION 'Дата рождения не может быть раньше 1000 года.';
        END IF;
    END IF;

    -- Обновление питомца
    UPDATE pets
    SET 
        pet_name = COALESCE(p_new_pet_name, pet_name),  -- Если новое имя не передано, оставляем старое
        species = COALESCE(p_new_species, species),
        breed = COALESCE(p_new_breed, breed),
        birth_date = COALESCE(p_new_birth_date, birth_date)
    WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    RAISE NOTICE 'Питомец % успешно обновлен.', p_pet_name;
END;
$$;




CREATE OR REPLACE PROCEDURE delete_pet_for_client(p_pet_name VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    p_owner_id INT;
BEGIN
    -- Получаем owner_id питомца через представление client_pets_view
    SELECT owner_id INTO p_owner_id
    FROM client_pets_view
    WHERE pet_name = p_pet_name
    LIMIT 1;

    -- Проверка на существование питомца у текущего владельца
    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден для владельца %.', p_pet_name, CURRENT_USER;
    END IF;

    -- Удаление питомца
    DELETE FROM pets WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    RAISE NOTICE 'Питомец с именем % успешно удален.', p_pet_name;
END;
$$;
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_review_for_client(
    p_service_name VARCHAR,               -- Название услуги
    p_veterinarian_last_name VARCHAR,      -- Фамилия ветеринара
    p_rating INT,                          -- Оценка
    p_review_text TEXT,                    -- Текст отзыва
    p_response_text TEXT DEFAULT NULL      -- Текст ответа (по желанию)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_client_id INT;
    v_service_id INT;
    v_veterinarian_id INT;
BEGIN
    -- Получаем ID клиента через представление client_user_view
    SELECT client_id INTO v_client_id
    FROM client_user_view
    WHERE username = CURRENT_USER
    LIMIT 1;

    IF v_client_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с логином % не найден.', CURRENT_USER;
    END IF;

    -- Получаем ID услуги по названию
    SELECT service_id INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга % не найдена.', p_service_name;
    END IF;

    -- Получаем ID ветеринара через представление employees_view
    SELECT employee_id INTO v_veterinarian_id
    FROM employees_view
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
    END IF;

    -- Вставка отзыва с привязкой к клиенту, услуге и ветеринару
    INSERT INTO reviews (client_id, service_id, rating, review_text, response_text)
    VALUES (v_client_id, v_service_id, p_rating, p_review_text, p_response_text);

    RAISE NOTICE 'Отзыв успешно добавлен для клиента % по услуге % с участием ветеринара %.', CURRENT_USER, p_service_name, p_veterinarian_last_name;
END;
$$;
-----------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION search_services(
    p_search_query TEXT
)
RETURNS TABLE (
    service_id INT,
    service_name VARCHAR,
    description TEXT,
    price NUMERIC,
    available BOOLEAN,
    veterinarian_first_name VARCHAR,
    veterinarian_last_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        s.service_id, 
        s.service_name, 
        s.description, 
        s.price, 
        s.available, 
        s.veterinarian_first_name, 
        s.veterinarian_last_name
    FROM services s
    WHERE 
        s.available = TRUE AND (
            s.service_name ILIKE '%' || p_search_query || '%' OR 
            s.description ILIKE '%' || p_search_query || '%'
        );
END;
$$;

select * from services;

SELECT * FROM search_services('терапевтом');

CREATE OR REPLACE FUNCTION sort_services(
    p_sort_by TEXT,          -- Поле для сортировки
    p_sort_order TEXT        -- Порядок сортировки (ASC, DESC)
)
RETURNS TABLE (
    service_id INT,
    service_name VARCHAR,
    description TEXT,
    price NUMERIC,
    available BOOLEAN,
    veterinarian_first_name VARCHAR,
    veterinarian_last_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Проверяем корректность полей для сортировки
    IF NOT p_sort_by IN ('price', 'service_name', 'veterinarian_last_name') THEN
        RAISE EXCEPTION 'Недопустимое поле для сортировки: %', p_sort_by;
    END IF;

    IF NOT p_sort_order IN ('ASC', 'DESC') THEN
        RAISE EXCEPTION 'Недопустимый порядок сортировки: %', p_sort_order;
    END IF;

    -- Динамическое выполнение запроса
    RETURN QUERY EXECUTE FORMAT(
        'SELECT 
            s.service_id, 
            s.service_name, 
            s.description, 
            s.price::NUMERIC, 
            s.available, 
            s.veterinarian_first_name, 
            s.veterinarian_last_name
         FROM services s
         WHERE s.available = TRUE
         ORDER BY %I %s', 
        p_sort_by, p_sort_order
    );
END;
$$;
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE book_appointment_for_client(
    p_pet_name VARCHAR,               
    p_service_name VARCHAR,           
    p_appointment_date TIMESTAMP,     
    p_complaint TEXT DEFAULT NULL,    
    p_veterinarian_last_name VARCHAR DEFAULT NULL   
)
LANGUAGE plpgsql AS $$
DECLARE
    p_pet_id INT;
    p_service_id INT;
    p_owner_id INT;
    p_veterinarian_id INT;
BEGIN
    -- Получаем ID питомца
    SELECT pet_id, owner_id INTO p_pet_id, p_owner_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF p_pet_id IS NULL THEN
        RAISE EXCEPTION 'Питомец с именем % не найден.', p_pet_name;
    END IF;

    -- Получаем ID клиента
    SELECT client_id INTO p_owner_id
    FROM client_user_view
    WHERE username = CURRENT_USER
    LIMIT 1;

    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Владелец с логином % не найден.', CURRENT_USER;
    END IF;

    IF p_owner_id != (SELECT owner_id FROM pets WHERE pet_id = p_pet_id) THEN
        RAISE EXCEPTION 'Питомец % не принадлежит владельцу с логином %.', p_pet_name, CURRENT_USER;
    END IF;

    -- Получаем ID услуги
    SELECT service_id INTO p_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF p_service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга % не найдена.', p_service_name;
    END IF;

    -- Проверка на дублирующую запись
    IF EXISTS (
        SELECT 1
        FROM appointments a
        JOIN services s ON a.service_id = s.service_id
        WHERE a.appointment_date = p_appointment_date
        AND s.service_name = p_service_name
    ) THEN
        RAISE EXCEPTION 'На указанное время для услуги % уже есть запись.', p_service_name;
    END IF;

    -- Получение ID ветеринара через представление
    IF p_veterinarian_last_name IS NOT NULL THEN
        SELECT employee_id INTO p_veterinarian_id
        FROM vet_view
        WHERE last_name = p_veterinarian_last_name
        LIMIT 1;

        IF p_veterinarian_id IS NULL THEN
            RAISE EXCEPTION 'Ветеринар с фамилией % не найден.', p_veterinarian_last_name;
        END IF;

        -- Проверка возможности предоставления услуги
        IF NOT EXISTS (
            SELECT 1
            FROM vet_service_mapping
            WHERE position = (SELECT position FROM vet_view WHERE employee_id = p_veterinarian_id)
            AND service_name = p_service_name
        ) THEN
            RAISE EXCEPTION 'Ветеринар с фамилией % не может предоставить услугу %.', p_veterinarian_last_name, p_service_name;
        END IF;
    ELSE
        -- Автоматический выбор ветеринара
        SELECT veterinarian_id INTO p_veterinarian_id
        FROM services
        WHERE service_id = p_service_id
        LIMIT 1;
    END IF;

    -- Добавление записи
    INSERT INTO appointments (pet_id, service_id, appointment_date, complaint, veterinarian_id)
    VALUES (p_pet_id, p_service_id, p_appointment_date, p_complaint, p_veterinarian_id);

    RAISE NOTICE 'Запись на прием для питомца % на услугу % успешно добавлена.', p_pet_name, p_service_name;
END;
$$;
