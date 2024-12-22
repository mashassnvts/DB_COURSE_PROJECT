--таблицы
-- Drop tables if they exist
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS appointments;

ALTER TABLE users CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE employees CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE users MODIFY username VARCHAR(255) COLLATE utf8mb4_unicode_ci;
ALTER TABLE employees MODIFY first_name VARCHAR(100) COLLATE utf8mb4_unicode_ci;
ALTER TABLE users MODIFY username VARCHAR(255) COLLATE utf8mb4_unicode_ci;
ALTER TABLE users COLLATE utf8mb4_unicode_ci;
ALTER DATABASE course COLLATE utf8mb4_unicode_ci;
ALTER TABLE users COLLATE utf8mb4_unicode_ci;
ALTER TABLE employees COLLATE utf8mb4_unicode_ci;



-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,           
    username VARCHAR(50) NOT NULL UNIQUE, 
    password_hash TEXT NOT NULL,          
    role ENUM('admin', 'employee', 'client') NOT NULL  -- Роли пользователей
);
INSERT INTO users (username, password_hash, role)
VALUES (
    p_username COLLATE utf8mb4_unicode_ci,
    p_password_hash, 
    p_role COLLATE utf8mb4_unicode_ci
);




-- Таблица сотрудников
CREATE TABLE IF NOT EXISTS employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY, 
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100), 
    hire_date DATE NOT NULL,
    user_id INT UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE  -- Связь с таблицей users
);

-- Таблица клиентов
CREATE TABLE IF NOT EXISTS clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    user_id INT UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE  -- Связь с таблицей users
);

-- Таблица животных
CREATE TABLE IF NOT EXISTS pets (
    pet_id INT AUTO_INCREMENT PRIMARY KEY,
    pet_name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,
    breed VARCHAR(50),
    birth_date DATE,
    owner_id INT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES clients(client_id) ON DELETE CASCADE
);

-- Таблица услуг
CREATE TABLE IF NOT EXISTS services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,              -- Идентификатор услуги
    service_name VARCHAR(100) NOT NULL,         -- Название услуги
    description TEXT,                           -- Описание услуги
    price DECIMAL(10, 2) NOT NULL,              -- Цена услуги
    available BOOLEAN DEFAULT TRUE,             -- Доступность услуги
    veterinarian_id INT NOT NULL,               -- ID ветеринара
    veterinarian_first_name VARCHAR(100),       -- Имя ветеринара
    veterinarian_last_name VARCHAR(100),        -- Фамилия ветеринара
    FOREIGN KEY (veterinarian_id) REFERENCES employees(employee_id) ON DELETE CASCADE -- Врач, который предоставляет эту услугу
);

ALTER TABLE services
ADD COLUMN service_time TIMESTAMP;  -- Добавление столбца для времени услуги

-- Таблица записей на прием
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,   -- Идентификатор записи
    pet_id INT NOT NULL,
    service_id INT NOT NULL,
    appointment_date TIMESTAMP NOT NULL, 
    complaint TEXT,                      
    veterinarian_id INT NOT NULL,
    notes TEXT,
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE, 
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    FOREIGN KEY (veterinarian_id) REFERENCES employees(employee_id)
);

ALTER TABLE pets ADD COLUMN owner_last_name VARCHAR(255);

-- Таблица диагнозов
CREATE TABLE IF NOT EXISTS diagnoses (
    diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,                      -- Идентификатор диагноза
    pet_id INT NOT NULL,
    veterinarian_id INT NOT NULL,
    diagnosis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,              -- Дата диагноза
    diagnosis_text TEXT NOT NULL,                        -- Описание диагноза
    notes TEXT,                                           -- Дополнительные заметки
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE, 
    FOREIGN KEY (veterinarian_id) REFERENCES employees(employee_id)
);

-- Добавление связи с диагнозами в таблицу рецептов
ALTER TABLE prescriptions
ADD COLUMN diagnosis_id INT,
ADD FOREIGN KEY (diagnosis_id) REFERENCES diagnoses(diagnosis_id) ON DELETE CASCADE;

-- Таблица отзывов
CREATE TABLE IF NOT EXISTS reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    service_id INT DEFAULT NULL, -- Allow service_id to be NULL
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    review_text TEXT,
    response_text TEXT,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL
);


ALTER TABLE reviews ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Таблица рецептов
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    pet_id INT NOT NULL,
    veterinarian_id INT NOT NULL,
    prescription_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    medication_name VARCHAR(150) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    administration_method VARCHAR(100),
    treatment_duration VARCHAR(50),
    notes TEXT,
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE,
    FOREIGN KEY (veterinarian_id) REFERENCES employees(employee_id)
);

-- Таблица соответствия ветеринаров и услуг
CREATE TABLE IF NOT EXISTS vet_service_mapping (
    position VARCHAR(255),        -- Должность ветеринара
    service_name VARCHAR(255)     -- Название услуги
);

TRUNCATE TABLE users ;

DROP TABLE IF EXISTS vet_service_mapping;

-- Наполнение таблицы соответствия
INSERT INTO vet_service_mapping (position, service_name)
VALUES
    ('Ветеринарный терапевт', 'Консультация по общему состоянию здоровья животного'),
    ('Ветеринарный хирург', 'Хирургическое вмешательство при травмах'),
    ('Ветеринарный офтальмолог', 'Операции на глазах'),
    ('Ветеринарный кардиолог', 'Диагностика сердечно-сосудистых заболеваний'),
    ('Ветеринарный терапевт', 'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных'),
    ('Ветеринарный хирург', 'Удаление опухолей и новообразований'),
    ('Ветеринарный офтальмолог', 'Лечение глаукомы и катаракты у животных'),
    ('Ветеринарный кардиолог', 'Лечение сердечной недостаточности у домашних животных');


