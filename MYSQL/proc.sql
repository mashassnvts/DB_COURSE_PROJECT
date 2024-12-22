ALTER DATABASE course COLLATE utf8mb4_unicode_ci;

--админ
CALL add_user('testikk', 'Pass12345', 'client', 'Test', 'Client', 'test@example.com', '+1234567890', null);
CALL update_user('testikk', 'NewPass12345', 'client', 'Test', 'Clientt', 'testt@example.com', '+1234567899', null);
CALL delete_user('testikk');


CALL add_employee('annn', 'password12345', 'Аничка', 'Пузирева', 'Veterinary Therapist');
CALL update_employee(73, 'John', 'John', 'Veterinary Surgeon');
CALL delete_employee(73);

CALL add_client('testuser1', 'Password12346', 'John', 'Doe', 'john@example.com', '1234567890');
CALL update_client('testuser1', 'NewPassword5678', 'Jane', NULL, NULL, NULL);
CALL delete_user('testuser1');

CALL add_pet_for_admin('Рекс', 'Собака', 'Лабрадор', '2018-05-01', 'testuser1');
CALL update_pet_for_admin('Рекс', 'testuser1', 'Макс', 'Собака', 'Лабрадор', '2018-05-01');
CALL delete_pet_for_admin('Рекс', 'testuser1');


CALL add_service_for_admin('Консультация по общему состоянию здоровья животного', 1000.00, 'Бунинаэ', '2024-12-24 10:00:00', 'Общее обследование', TRUE);
CALL add_service_for_admin('Консультация по общему состоянию здоровья животного', 1000.00, 'Бунинаэ', '2024-12-24 11:00:00', 'Общее обследование', TRUE);
CALL add_service_for_admin('Консультация по общему состоянию здоровья животного', 1000.00, 'Бунинаэ', '2024-12-24 12:00:00', 'Общее обследование', TRUE);

CALL add_appointment('Рекс', 'Консультация по общему состоянию здоровья животного', '2024-12-24 12:00:00', 'Бунинаэ', 'Нет', '');
SET @last_id = LAST_INSERT_ID();
CALL update_appointment(@last_id, 'Рекс', 'Консультация по общему состоянию здоровья животного', '2024-12-24 11:00:00', 'Бунинаэ', 'Проблема с лапой', 'Проверить.');
CALL delete_appointment(@last_id);
SELECT 
    a.appointment_id,
    p.pet_name,
    s.service_name,
    a.appointment_date,
    a.complaint,
    e.last_name AS veterinarian_last_name,
    a.notes
FROM appointments a
JOIN pets p ON a.pet_id = p.pet_id
join services s ON a.service_id = s.service_id
JOIN employees e ON a.veterinarian_id = e.employee_id;


CALL add_diagnosis('Рекс', 'Бунинаэ', 'Пневмония', 'Рекомендуется курс антибиотиков');
CALL update_diagnosis('Рекс', 'Бунинаэ', 'Обновленный диагноз', 'Обновленные заметки');
CALL delete_diagnosis('Рекс', 'Бунинаэ');


CALL add_review_for_admin('John Doe', 'Консультация по общему состоянию здоровья животного', 'Бунинаэ', 5, 'Отличная работа!', 'Спасибо за отзыв.');
CALL update_review_for_admin(800111, 4, 'Обновленный текст отзыва.', 'Ответ на отзыв.');
CALL delete_review_for_admin(800111);

CALL add_prescription_by_pet_name(
    'Рекс', 
    'Бунинаэ', 
    'Антибиотик', 
    '1 таблетка', 
    'Перорально', 
    '7 дней', 
    'Принимать после еды'
);


CALL update_prescription_by_pet_name(
    'Рекс', 
    'Бунинаэ', 
    'Антибиотик', 
    '2 таблетки', 
    'Перорально', 
    '10 дней', 
    'Принимать после еды'
);

CALL delete_prescription_by_pet_name(
    'Рекс', 
    'Бунинаэ', 
    'Антибиотик'
);


select * from users u ;
select * from clients c ;
select * from employees e ;
select * from pets;
select * from services;
select * from diagnoses;
select * from reviews;
select * from prescriptions;

DROP PROCEDURE IF EXISTS add_prescription_by_pet_name;


DELIMITER //

CREATE PROCEDURE add_user(
    IN p_username VARCHAR(50),
    IN p_password TEXT,
    IN p_role ENUM('admin', 'employee', 'client'),
    IN p_first_name VARCHAR(255),
    IN p_last_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(50),
    IN p_position VARCHAR(255)
)
BEGIN
    DECLARE p_password_hash TEXT;
    DECLARE digit_count INT;

    -- Check for allowed characters in the username (only letters and underscore "_")
    IF NOT p_username REGEXP '^[A-Za-z_]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username can only contain letters and underscores ("_").';
    END IF;

    -- Check if a user with that username already exists
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User with the specified name already exists.';
    END IF;

    -- Check for unique email
    IF EXISTS (SELECT 1 FROM clients WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is already registered in the system.';
    END IF;

    -- Check for valid email format
IF NOT p_email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format.';
    END IF;

    -- Check for unique phone number
    IF EXISTS (SELECT 1 FROM clients WHERE phone = p_phone) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number is already registered in the system.';
    END IF;

    -- Check for valid phone number format
IF NOT p_phone REGEXP '^\\+?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number must start with "+" and contain only digits.';
    END IF;

    -- Check for valid position
    IF TRIM(p_position) NOT IN ('Veterinary Therapist', 'Veterinary Surgeon', 'Veterinary Ophthalmologist', 'Veterinary Cardiologist') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid position.';
    END IF;

    -- Hash the password
    SET p_password_hash = SHA2(CONCAT(p_password, 'your_salt_here'), 256);

    -- Check for the number of digits in the password
    SELECT LENGTH(REGEXP_REPLACE(p_password, '[^0-9]', '')) INTO digit_count;
    IF digit_count < 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must contain at least 5 digits';
    END IF;

    -- Insert the new user into the users table
    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, p_role);

    SET @new_user_id = LAST_INSERT_ID();

    -- Insert user data into clients or employees table depending on the role
    IF p_role = 'client' THEN
        INSERT INTO clients (user_id, first_name, last_name, phone, email)
        VALUES (@new_user_id, p_first_name, p_last_name, p_phone, p_email);
    ELSEIF p_role = 'employee' THEN
        INSERT INTO employees (user_id, first_name, last_name, position, hire_date)
        VALUES (@new_user_id, p_first_name, p_last_name, p_position, CURRENT_DATE());
    END IF;

    SELECT CONCAT('User ', p_username, ' with role ', p_role, ' successfully added.') AS message;
END //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE update_user(
    IN p_username VARCHAR(50),
    IN p_password TEXT,
    IN p_role ENUM('admin', 'employee', 'client'),
    IN p_first_name VARCHAR(255),
    IN p_last_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(50),
    IN p_position VARCHAR(255)
)
BEGIN
    DECLARE p_password_hash TEXT;
    DECLARE digit_count INT;

    -- Validate input data using same checks as in add_user
    IF NOT p_username REGEXP '^[A-Za-z_]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username can only contain letters and underscores ("_").';
    END IF;

   IF NOT p_email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format.';
    END IF;

   IF NOT p_phone REGEXP '^\\+?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number must start with "+" and contain only digits.';
    END IF;

    IF TRIM(p_position) NOT IN ('Veterinary Therapist', 'Veterinary Surgeon', 'Veterinary Ophthalmologist', 'Veterinary Cardiologist') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid position.';
    END IF;

    SET p_password_hash = SHA2(CONCAT(p_password, 'your_salt_here'), 256);

    SELECT LENGTH(REGEXP_REPLACE(p_password, '[^0-9]', '')) INTO digit_count;
    IF digit_count < 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must contain at least 5 digits';
    END IF;

    -- Update users and related tables
    UPDATE users SET password_hash = p_password_hash, role = p_role WHERE username = p_username;

    IF p_role = 'client' THEN
        UPDATE clients SET first_name = p_first_name, last_name = p_last_name, phone = p_phone, email = p_email
        WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    ELSEIF p_role = 'employee' THEN
        UPDATE employees SET first_name = p_first_name, last_name = p_last_name, position = p_position
        WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    END IF;

    SELECT CONCAT('User ', p_username, ' successfully updated.') AS message;
END //

CREATE PROCEDURE delete_user(
    IN p_username VARCHAR(50)
)
BEGIN
    DELETE FROM clients WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    DELETE FROM employees WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    DELETE FROM users WHERE username = p_username;
    SELECT CONCAT('User ', p_username, ' successfully deleted.') AS message;
END //

DELIMITER ;

------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE add_employee(
    IN p_username VARCHAR(50),
    IN p_password TEXT,
    IN p_first_name VARCHAR(255),
    IN p_last_name VARCHAR(255),
    IN p_position VARCHAR(255)
)
BEGIN
    DECLARE p_password_hash TEXT;
    DECLARE digit_count INT;
    DECLARE new_user_id INT;

    -- Проверка, что имя пользователя состоит только из букв и символа подчеркивания ("_")
    IF NOT p_username REGEXP '^[A-Za-z_]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username can only contain letters and underscores ("_").';
    END IF;

    -- Проверка, существует ли пользователь с таким именем
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User with the specified name already exists.';
    END IF;

    -- Хеширование пароля
    SET p_password_hash = SHA2(CONCAT(p_password, 'your_salt_here'), 256);

    -- Проверка на количество цифр в пароле
    SELECT LENGTH(REGEXP_REPLACE(p_password, '[^0-9]', '')) INTO digit_count;
    IF digit_count < 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must contain at least 5 digits';
    END IF;

    -- Вставка нового пользователя в таблицу пользователей с ролью 'employee'
    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, 'employee');

    SET new_user_id = LAST_INSERT_ID();

    -- Проверка на допустимые должности
    IF TRIM(p_position) NOT IN ('Veterinary Therapist', 'Veterinary Surgeon', 'Veterinary Ophthalmologist', 'Veterinary Cardiologist') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid position.';
    END IF;

    -- Вставка информации о сотруднике в таблицу employees
    INSERT INTO employees (user_id, first_name, last_name, position, hire_date)
    VALUES (new_user_id, p_first_name, p_last_name, p_position, CURRENT_DATE());

    -- Сообщение об успешном добавлении сотрудника
    SELECT CONCAT('Employee ', p_username, ' successfully added.') AS message;

END $$

DELIMITER ;

DELIMITER //

CREATE PROCEDURE update_employee(
    IN p_employee_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_position VARCHAR(100)
)
BEGIN
    -- Проверка существования сотрудника по employee_id
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
    END IF;

    -- Проверка корректности позиции, если она указана
    IF p_position IS NOT NULL AND TRIM(p_position) NOT IN ('Veterinary Therapist', 'Veterinary Surgeon', 'Veterinary Ophthalmologist', 'Veterinary Cardiologist') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid position.';
    END IF;

    -- Обновление данных сотрудника
    UPDATE employees
    SET 
        first_name = COALESCE(p_first_name, first_name), -- Если новое имя пустое, оставляем старое
        last_name = COALESCE(p_last_name, last_name), -- То же для фамилии
        position = COALESCE(p_position, position) -- То же для должности
    WHERE employee_id = p_employee_id;

    -- Вывод сообщения о успешном обновлении
    SELECT CONCAT('Employee with ID ', p_employee_id, ' successfully updated.') AS message;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE delete_employee(
    IN p_employee_id INT
)
BEGIN
    -- Проверка существования сотрудника
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
    END IF;

    -- Удаление сотрудника
    DELETE FROM employees WHERE employee_id = p_employee_id;

    -- Вывод сообщения о успешном удалении
    SELECT CONCAT('Employee with ID ', p_employee_id, ' successfully deleted.') AS message;
END //

DELIMITER ;
------------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE add_client(
    IN p_username VARCHAR(255), 
    IN p_password TEXT, 
    IN p_first_name VARCHAR(100), 
    IN p_last_name VARCHAR(100), 
    IN p_email VARCHAR(255), 
    IN p_phone VARCHAR(50)
)
BEGIN
    DECLARE p_password_hash TEXT;
    DECLARE new_user_id INT;
    DECLARE digit_count INT DEFAULT 0;
    DECLARE i INT DEFAULT 1;

    -- Установка значений по умолчанию, если они NULL
    IF p_first_name IS NULL THEN
        SET p_first_name = 'Unknown';
    END IF;
    IF p_last_name IS NULL THEN
        SET p_last_name = 'Unknown';
    END IF;
    IF p_email IS NULL THEN
        SET p_email = 'example@example.com';
    END IF;
    IF p_phone IS NULL THEN
        SET p_phone = 'Unknown';
    END IF;

    -- Проверка на существование пользователя
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Пользователь с именем уже существует.';
    END IF;

    -- Хеширование пароля
    SET p_password_hash = SHA2(CONCAT(p_password, 'your_salt'), 256); -- Замените 'your_salt' на свой соль

    -- Подсчёт количества цифр в пароле
    WHILE i <= LENGTH(p_password) DO
        IF MID(p_password, i, 1) RLIKE '[0-9]' THEN
            SET digit_count = digit_count + 1;
        END IF;
        SET i = i + 1;
    END WHILE;

    IF digit_count < 5 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Пароль должен содержать не менее 5 цифр';
    END IF;

    -- Вставка нового пользователя
    INSERT INTO users (username, password_hash, role)
    VALUES (p_username, p_password_hash, 'client');

    -- Получение ID нового пользователя
    SET new_user_id = LAST_INSERT_ID();

    -- Вставка клиента
    INSERT INTO clients (user_id, first_name, last_name, phone, email)
    VALUES (new_user_id, p_first_name, p_last_name, p_phone, p_email);
    
    SELECT CONCAT('Клиент ', p_username, ' успешно добавлен.') AS message;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE update_client(
    IN p_username VARCHAR(255), 
    IN p_password TEXT, 
    IN p_first_name VARCHAR(100), 
    IN p_last_name VARCHAR(100), 
    IN p_email VARCHAR(255), 
    IN p_phone VARCHAR(50)
)
BEGIN
    DECLARE p_password_hash TEXT;
    DECLARE p_user_id INT;

    -- Получение ID пользователя
    SELECT user_id INTO p_user_id FROM users WHERE username = p_username;

    IF p_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Пользователь не найден.';
    END IF;

    -- Хеширование нового пароля
    IF p_password IS NOT NULL THEN
        SET p_password_hash = SHA2(CONCAT(p_password, 'your_salt'), 256); -- Замените 'your_salt' на свой соль
    END IF;

    -- Обновление данных пользователя
    UPDATE users
    SET 
        password_hash = COALESCE(p_password_hash, password_hash)
    WHERE user_id = p_user_id;

    -- Обновление данных клиента
    UPDATE clients
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone)
    WHERE user_id = p_user_id;

    SELECT CONCAT('Данные клиента ', p_username, ' обновлены.') AS message;
END //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE add_pet_for_admin(
    IN p_pet_name VARCHAR(255),            -- Имя питомца
    IN p_species VARCHAR(255),             -- Вид питомца
    IN p_breed VARCHAR(255),               -- Порода питомца
    IN p_birth_date DATE,                  -- Дата рождения питомца
    IN p_username VARCHAR(255)              -- Логин пользователя, для которого добавляется питомец
)
BEGIN
    DECLARE p_owner_id INT;                -- Переменная для хранения ID владельца
    DECLARE current_date_var DATE;         -- Текущая дата
    DECLARE error_message VARCHAR(255);     -- Переменная для хранения сообщения об ошибке
    DECLARE valid_breeds VARCHAR(255);      -- Переменная для хранения допустимых пород

    SET current_date_var = CURDATE();      -- Присваиваем текущее значение
    SET valid_breeds = '';                  -- Инициализация переменной для пород

    -- Проверка на формат даты рождения
    IF p_birth_date IS NULL THEN
        SET error_message = 'Дата рождения не может быть NULL.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Получаем ID владельца по логину пользователя
    SELECT c.client_id INTO p_owner_id
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    WHERE u.username = p_username
    LIMIT 1;

    -- Проверка на существование владельца
    IF p_owner_id IS NULL THEN
        SET error_message = CONCAT('Владелец с логином ', p_username, ' не найден.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Валидация имени питомца
    IF p_pet_name IS NULL OR CHAR_LENGTH(TRIM(p_pet_name)) < 3 THEN
        SET error_message = 'Имя питомца должно содержать минимум 3 символа.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    IF p_pet_name NOT REGEXP '^[А-Яа-яA-Za-z ]+$' THEN
        SET error_message = 'Имя питомца должно содержать только буквы.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Валидация даты рождения
    IF p_birth_date > current_date_var THEN
        SET error_message = 'Дата рождения не может быть в будущем.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    IF YEAR(p_birth_date) < 1000 THEN
        SET error_message = 'Дата рождения не может быть раньше 1000 года.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Валидация вида питомца и пород
    CASE p_species
        WHEN 'Собака' THEN SET valid_breeds = 'Лабрадор, Немецкая овчарка';
        WHEN 'Кошка' THEN SET valid_breeds = 'Сиамская, Персидская, Британец';
        WHEN 'Попугай' THEN SET valid_breeds = 'Ара, Жако';
        WHEN 'Хомяк' THEN SET valid_breeds = 'Сирийский, Джунгарский';
        WHEN 'Кролик' THEN SET valid_breeds = 'Мини-ломброза, Ангорский';
        ELSE
            SET error_message = 'Вид питомца должен быть одним из следующих: Собака, Кошка, Попугай, Хомяк, Кролик.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END CASE;

    -- Проверка на допустимость породы для выбранного вида
    IF p_breed IS NOT NULL AND FIND_IN_SET(p_breed, valid_breeds) = 0 THEN
        SET error_message = CONCAT('Порода ', p_breed, ' не подходит для вида питомца ', p_species, '.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Добавление питомца
    INSERT INTO pets (pet_name, species, breed, birth_date, owner_id)
    VALUES (p_pet_name, p_species, p_breed, p_birth_date, p_owner_id);

    SELECT CONCAT('Питомец ', p_pet_name, ' успешно добавлен владельцу с логином ', p_username) AS message;
END //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE update_pet_for_admin(
    IN p_pet_name VARCHAR(255),              -- Имя питомца, которое нужно обновить
    IN p_username VARCHAR(255),              -- Логин владельца питомца
    IN p_new_pet_name VARCHAR(255),          -- Новое имя питомца (если нужно)
    IN p_new_species VARCHAR(255),           -- Новый вид питомца (если нужно)
    IN p_new_breed VARCHAR(255),             -- Новая порода питомца (если нужно)
    IN p_new_birth_date DATE                  -- Новая дата рождения питомца
)
BEGIN
    DECLARE p_owner_id INT;                  -- Переменная для хранения ID владельца
    DECLARE current_date_var DATE;           -- Текущая дата
    DECLARE current_species VARCHAR(255);     -- Текущий вид питомца
    DECLARE error_message VARCHAR(255);       -- Переменная для хранения сообщения об ошибке

    SET current_date_var = CURDATE();        -- Присваиваем текущее значение

    -- Получаем ID владельца питомца по логину
    SELECT c.client_id, p.species INTO p_owner_id, current_species
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    JOIN pets p ON p.owner_id = c.client_id
    WHERE u.username = p_username AND p.pet_name = p_pet_name
    LIMIT 1;

    -- Проверка на существование владельца и питомца
    IF p_owner_id IS NULL THEN
        SET error_message = CONCAT('Питомец с именем ', p_pet_name, ' не найден для владельца с логином ', p_username, '.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Валидация новых значений (если они не NULL)
    IF p_new_pet_name IS NOT NULL THEN
        IF CHAR_LENGTH(TRIM(p_new_pet_name)) < 3 THEN
            SET error_message = 'Новое имя питомца должно содержать минимум 3 символа.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

        IF p_new_pet_name NOT REGEXP '^[А-Яа-яA-Za-z ]+$' THEN
            SET error_message = 'Новое имя питомца должно содержать только буквы.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;
    END IF;

    IF p_new_birth_date IS NOT NULL THEN
        IF p_new_birth_date > current_date_var THEN
            SET error_message = 'Дата рождения не может быть в будущем.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

        IF YEAR(p_new_birth_date) < 1000 THEN
            SET error_message = 'Дата рождения не может быть раньше 1000 года.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;
    END IF;

    -- Обновление питомца
    UPDATE pets
    SET 
        pet_name = COALESCE(p_new_pet_name, pet_name),
        species = COALESCE(p_new_species, species),
        breed = COALESCE(p_new_breed, breed),
        birth_date = COALESCE(p_new_birth_date, birth_date)
    WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    SELECT CONCAT('Питомец ', p_pet_name, ' успешно обновлен владельцу с логином ', p_username) AS message;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE delete_pet_for_admin(
    IN p_pet_name VARCHAR(255), 
    IN p_username VARCHAR(255)
)
BEGIN
    DECLARE p_owner_id INT;                 -- Переменная для хранения ID владельца
    DECLARE error_message VARCHAR(255);      -- Переменная для хранения сообщения об ошибке

    -- Получаем ID владельца по логину пользователя
    SELECT c.client_id INTO p_owner_id
    FROM clients c
    JOIN users u ON c.user_id = u.user_id
    WHERE u.username = p_username
    LIMIT 1;

    -- Проверка на существование владельца
    IF p_owner_id IS NULL THEN
        SET error_message = CONCAT('Владелец с логином ', p_username, ' не найден.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Проверка на существование питомца у владельца
    IF NOT EXISTS (SELECT 1 FROM pets WHERE pet_name = p_pet_name AND owner_id = p_owner_id) THEN
        SET error_message = CONCAT('Питомец с именем ', p_pet_name, ' не найден для владельца ', p_username, '.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Удаление питомца
    DELETE FROM pets WHERE pet_name = p_pet_name AND owner_id = p_owner_id;

    SELECT CONCAT('Питомец с именем ', p_pet_name, ' успешно удален владельцу с логином ', p_username) AS message;
END //

DELIMITER ;
-------------------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE add_service_for_admin(
    IN p_service_name VARCHAR(255),
    IN p_price DECIMAL(10, 2),
    IN p_veterinarian_last_name VARCHAR(255),
    IN p_service_time TIMESTAMP,
    IN p_description TEXT,
    IN p_available BOOLEAN
)
BEGIN
    DECLARE vet_id INT;
    DECLARE vet_position VARCHAR(255);

    SELECT employee_id, position INTO vet_id, vet_position
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF vet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ветеринар не найден.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM vet_service_mapping
        WHERE position = vet_position AND service_name = p_service_name
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Услуга не может быть предоставлена данным ветеринаром.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM services
        WHERE veterinarian_id = vet_id
        AND service_time = p_service_time
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Услуга с таким временем уже существует для данного ветеринара.';
    END IF;

    IF p_service_time < CURRENT_TIMESTAMP THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Дата услуги должна быть не раньше сегодняшнего дня.';
    END IF;

    IF p_description IS NOT NULL AND p_description NOT REGEXP '^[А-Яа-яA-Za-z0-9,."'' ]+$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Описание услуги должно содержать только буквы, цифры, пробелы и знаки препинания.';
    END IF;

    INSERT INTO services (service_name, price, veterinarian_id, veterinarian_first_name, veterinarian_last_name, service_time, available, description)
    VALUES (p_service_name, p_price, vet_id, (SELECT first_name FROM employees WHERE employee_id = vet_id), p_veterinarian_last_name, p_service_time, p_available, p_description);

    SELECT 'Услуга успешно добавлена для ветеринара.' AS message;
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE update_service_for_admin(
    IN p_service_id INT,
    IN p_service_name VARCHAR(255),
    IN p_price DECIMAL(10, 2),
    IN p_veterinarian_last_name VARCHAR(255),
    IN p_service_time TIMESTAMP,
    IN p_description TEXT,
    IN p_available BOOLEAN
)
BEGIN
    DECLARE vet_id INT;

    SELECT employee_id INTO vet_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF vet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ветеринар не найден.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM services
        WHERE veterinarian_id = vet_id
        AND service_time = p_service_time
        AND service_id != p_service_id
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Услуга с таким временем уже существует для данного ветеринара.';
    END IF;

    IF p_service_time < CURRENT_TIMESTAMP THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Дата услуги должна быть не раньше сегодняшнего дня.';
    END IF;

    IF p_description IS NOT NULL AND p_description NOT REGEXP '^[А-Яа-яA-Za-z0-9,."'' ]+$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Описание услуги должно содержать только буквы, цифры, пробелы и знаки препинания.';
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

    SELECT 'Услуга успешно обновлена.' AS message;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE delete_service_for_admin(
    IN p_service_id INT
)
BEGIN
    DECLARE service_exists INT;

    SELECT COUNT(*) INTO service_exists
    FROM services
    WHERE service_id = p_service_id;

    IF service_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Услуга не найдена.';
    END IF;

    DELETE FROM services
    WHERE service_id = p_service_id;

    SELECT 'Услуга успешно удалена.' AS message;
END //

DELIMITER ;
-----------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE add_appointment(
    IN p_pet_name VARCHAR(255),
    IN p_service_name VARCHAR(255),
    IN p_appointment_date TIMESTAMP,
    IN p_veterinarian_last_name VARCHAR(255),
    IN p_complaint TEXT,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_service_id INT;
    DECLARE v_vet_id INT;
    DECLARE v_client_id INT;

    -- Поиск питомца по кличке
    SELECT pet_id, owner_id 
    INTO v_pet_id, v_client_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    -- Если питомец не найден, выбрасываем исключение
    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец с кличкой не найден.';
    END IF;

    -- Поиск услуги по названию
    SELECT service_id 
    INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    -- Если услуга не найдена, выбрасываем исключение
    IF v_service_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Услуга с названием не найдена.';
    END IF;

    -- Поиск ветеринара по фамилии
    SELECT employee_id 
    INTO v_vet_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    -- Если ветеринар не найден, выбрасываем исключение
    IF v_vet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Проверка на занятость времени
    IF EXISTS (
        SELECT 1
        FROM appointments
        WHERE appointment_date = p_appointment_date 
          AND veterinarian_id = v_vet_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'На указанное время уже есть запись.';
    END IF;

    -- Добавление записи на прием
    INSERT INTO appointments (
        pet_id, service_id, appointment_date, complaint, veterinarian_id, notes
    )
    VALUES (
        v_pet_id, v_service_id, p_appointment_date, p_complaint, v_vet_id, p_notes
    );

    SELECT 'Запись на прием успешно добавлена.' AS message;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE update_appointment(
    IN p_appointment_id INT,
    IN p_pet_name VARCHAR(255),
    IN p_service_name VARCHAR(255),
    IN p_appointment_date TIMESTAMP,
    IN p_veterinarian_last_name VARCHAR(255),
    IN p_complaint TEXT,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_service_id INT;
    DECLARE v_vet_id INT;

    -- Проверяем, существует ли запись на прием с таким ID
    IF NOT EXISTS (
        SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Запись с ID не найдена.';
    END IF;

    -- Проверка существования питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец с кличкой не найден.';
    END IF;

    -- Проверка существования услуги
    SELECT service_id INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Услуга с названием не найдена.';
    END IF;

    -- Проверка существования ветеринара
    SELECT employee_id INTO v_vet_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_vet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Обновление записи на прием
    UPDATE appointments
    SET pet_id = v_pet_id,
        service_id = v_service_id,
        appointment_date = p_appointment_date,
        complaint = p_complaint,
        veterinarian_id = v_vet_id,
        notes = p_notes
    WHERE appointment_id = p_appointment_id;

    SELECT 'Запись с ID успешно обновлена.' AS message;
END $$

DELIMITER ;	

DELIMITER $$

CREATE PROCEDURE delete_appointment(
    IN p_appointment_id INT
)
BEGIN
    -- Проверяем существование записи на прием
    IF NOT EXISTS (
        SELECT 1 FROM appointments WHERE appointment_id = p_appointment_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Запись на прием с ID не найдена.';
    END IF;

    -- Удаление записи на прием
    DELETE FROM appointments
    WHERE appointment_id = p_appointment_id;

    SELECT 'Запись на прием успешно удалена.' AS message;
END $$

DELIMITER ;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE add_diagnosis(
    IN p_pet_name VARCHAR(255),               -- Имя питомца
    IN p_veterinarian_last_name VARCHAR(255), -- Фамилия ветеринара
    IN p_diagnosis_text TEXT,                  -- Текст диагноза
    IN p_notes TEXT                            -- Дополнительные заметки
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;

    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец не найден.';
    END IF;

    -- Проверка существования ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Проверка, что ветеринар связан с услугой для данного питомца
    IF NOT EXISTS (
        SELECT 1
        FROM appointments
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар не может добавить диагноз для питомца.';
    END IF;

    -- Добавление диагноза
    INSERT INTO diagnoses (pet_id, veterinarian_id, diagnosis_text, notes)
    VALUES (v_pet_id, v_veterinarian_id, p_diagnosis_text, p_notes);

    SELECT 'Диагноз успешно добавлен для питомца.' AS message;

END $$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE update_diagnosis(
    IN p_pet_name VARCHAR(255),               -- Имя питомца
    IN p_veterinarian_last_name VARCHAR(255), -- Фамилия ветеринара
    IN p_diagnosis_text TEXT,                  -- Текст диагноза
    IN p_notes TEXT                            -- Дополнительные заметки
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;

    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец не найден.';
    END IF;

    -- Получаем идентификатор ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Проверка, что этот ветеринар имеет диагноз для питомца
    IF NOT EXISTS (
        SELECT 1
        FROM diagnoses
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар не может обновить диагноз для питомца.';
    END IF;

    -- Обновление диагноза
    UPDATE diagnoses
    SET diagnosis_text = p_diagnosis_text, 
        notes = COALESCE(p_notes, notes)
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id;

    SELECT 'Диагноз для питомца успешно обновлен.' AS message;

END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE delete_diagnosis(
    IN p_pet_name VARCHAR(255),               -- Имя питомца
    IN p_veterinarian_last_name VARCHAR(255)  -- Фамилия ветеринара
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;

    -- Получаем идентификатор питомца
    SELECT pet_id INTO v_pet_id 
    FROM pets 
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец не найден.';
    END IF;

    -- Получаем идентификатор ветеринара
    SELECT employee_id INTO v_veterinarian_id 
    FROM employees 
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Проверка, что этот ветеринар имеет диагноз для питомца
    IF NOT EXISTS (
        SELECT 1
        FROM diagnoses
        WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар не может удалить диагноз для питомца.';
    END IF;

    -- Удаление диагноза
    DELETE FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id;

    SELECT 'Диагноз для питомца успешно удален.' AS message;

END $$

DELIMITER ;
-------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE add_review_for_admin(
    IN p_client_name VARCHAR(255),              -- Имя клиента
    IN p_service_name VARCHAR(255),             -- Название услуги
    IN p_veterinarian_last_name VARCHAR(255),   -- Фамилия ветеринара
    IN p_rating INT,                            -- Оценка
    IN p_review_text TEXT,                      -- Текст отзыва
    IN p_response_text TEXT                     -- Ответ (если есть)
)
BEGIN
    DECLARE v_client_id INT;
    DECLARE v_service_id INT;
    DECLARE v_veterinarian_id INT;

    -- Получение ID клиента
    SELECT client_id INTO v_client_id
    FROM clients
    WHERE CONCAT(first_name, ' ', last_name) = p_client_name
    LIMIT 1;

    IF v_client_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Клиент с именем не найден.';
    END IF;

    -- Получение ID услуги
    SELECT service_id INTO v_service_id
    FROM services
    WHERE service_name = p_service_name
    LIMIT 1;

    IF v_service_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Услуга не найдена.';
    END IF;

    -- Получение ID ветеринара
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Вставка отзыва
    INSERT INTO reviews (
        client_id, service_id, rating, review_text, response_text
    ) VALUES (
        v_client_id, v_service_id, p_rating, p_review_text, p_response_text
    );

    SELECT 'Отзыв успешно добавлен.' AS message;

END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE update_review_for_admin(
    IN p_review_id INT,                   -- ID отзыва
    IN p_rating INT,                      -- Оценка
    IN p_review_text TEXT,                -- Текст отзыва
    IN p_response_text TEXT                -- Ответ
)
BEGIN
    -- Проверка существования отзыва
    IF NOT EXISTS (SELECT 1 FROM reviews WHERE review_id = p_review_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Отзыв с таким ID не найден.';
    END IF;

    -- Обновление отзыва
    UPDATE reviews
    SET rating = p_rating, review_text = p_review_text, response_text = p_response_text
    WHERE review_id = p_review_id;

    SELECT CONCAT('Отзыв с ID ', p_review_id, ' обновлен.') AS message;
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE delete_review_for_admin(
    IN p_review_id INT  -- ID отзыва для удаления
)
BEGIN
    -- Проверка существования отзыва
    IF NOT EXISTS (SELECT 1 FROM reviews WHERE review_id = p_review_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Отзыв с таким ID не найден.';
    END IF;

    -- Удаление отзыва
    DELETE FROM reviews WHERE review_id = p_review_id;

    SELECT CONCAT('Отзыв с ID ', p_review_id, ' успешно удален.') AS message;
END $$

DELIMITER ;
---------------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE add_prescription_by_pet_name(
    IN p_pet_name VARCHAR(255),              -- Имя питомца
    IN p_veterinarian_last_name VARCHAR(255), -- Фамилия ветеринара
    IN p_medication_name VARCHAR(255),       -- Название лекарства
    IN p_dosage VARCHAR(255),                -- Дозировка
    IN p_administration_method VARCHAR(255), -- Способ применения
    IN p_treatment_duration VARCHAR(255),    -- Продолжительность лечения
    IN p_notes TEXT                         -- Примечания
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;
    DECLARE v_diagnosis_id INT;

    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец с именем не найден.';
    END IF;

    -- Получение ID ветеринара по фамилии
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Проверка наличия диагноза
    SELECT diagnosis_id INTO v_diagnosis_id
    FROM diagnoses
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id
    ORDER BY diagnosis_date DESC
    LIMIT 1;

    IF v_diagnosis_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Диагноз для питомца не найден.';
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

    SELECT 'Рецепт для питомца успешно добавлен.' AS message;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE update_prescription_by_pet_name(
    IN p_pet_name VARCHAR(255),            
    IN p_veterinarian_last_name VARCHAR(255),  
    IN p_medication_name VARCHAR(255),    
    IN p_new_dosage VARCHAR(255),         
    IN p_new_administration_method VARCHAR(255), 
    IN p_new_treatment_duration VARCHAR(255),    
    IN p_new_notes TEXT  
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;
    DECLARE v_prescription_id INT;

    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец с именем не найден.';
    END IF;

    -- Получение ID ветеринара по фамилии
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Получение ID рецепта
    SELECT prescription_id INTO v_prescription_id
    FROM prescriptions
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id 
          AND medication_name = p_medication_name
    ORDER BY prescription_date DESC
    LIMIT 1;

    IF v_prescription_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Рецепт для питомца не найден.';
    END IF;

    -- Обновление рецепта
    UPDATE prescriptions
    SET 
        dosage = p_new_dosage,
        administration_method = p_new_administration_method,
        treatment_duration = p_new_treatment_duration,
        notes = p_new_notes
    WHERE prescription_id = v_prescription_id;

    SELECT 'Рецепт для питомца успешно обновлен.' AS message;
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE delete_prescription_by_pet_name(
    IN p_pet_name VARCHAR(255),           
    IN p_veterinarian_last_name VARCHAR(255), 
    IN p_medication_name VARCHAR(255)    
)
BEGIN
    DECLARE v_pet_id INT;
    DECLARE v_veterinarian_id INT;
    DECLARE v_prescription_id INT;

    -- Получение ID питомца
    SELECT pet_id INTO v_pet_id
    FROM pets
    WHERE pet_name = p_pet_name
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Питомец с именем не найден.';
    END IF;

    -- Получение ID ветеринара по фамилии
    SELECT employee_id INTO v_veterinarian_id
    FROM employees
    WHERE last_name = p_veterinarian_last_name
    LIMIT 1;

    IF v_veterinarian_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ветеринар с фамилией не найден.';
    END IF;

    -- Получение ID рецепта
    SELECT prescription_id INTO v_prescription_id
    FROM prescriptions
    WHERE pet_id = v_pet_id AND veterinarian_id = v_veterinarian_id 
          AND medication_name = p_medication_name
    ORDER BY prescription_date DESC
    LIMIT 1;

    IF v_prescription_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Рецепт для питомца не найден.';
    END IF;

    -- Удаление рецепта
    DELETE FROM prescriptions
    WHERE prescription_id = v_prescription_id;

    SELECT 'Рецепт для питомца успешно удален.' AS message;
END $$

DELIMITER ;