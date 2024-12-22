--таблица пользователей+

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,           
    username VARCHAR(50) NOT NULL UNIQUE, 
    password_hash TEXT NOT NULL,          
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'employee', 'client'))  -- роли пользователей
);


--таблица сотрудников+
CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY, 
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100), 
    hire_date DATE NOT NULL,
    user_id INT UNIQUE REFERENCES users(user_id) ON DELETE CASCADE  -- связь с таблицей users
);



--таблица клиентов+
CREATE TABLE IF NOT EXISTS clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    user_id INT UNIQUE REFERENCES users(user_id) ON DELETE CASCADE  -- связь с таблицей users
);
 

--таблица животных+
CREATE TABLE IF NOT EXISTS pets (
    pet_id SERIAL PRIMARY KEY,
    pet_name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,
    breed VARCHAR(50),
    birth_date DATE,
    owner_id INT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE
);

--таблица услуг+
CREATE TABLE IF NOT EXISTS services (
    service_id SERIAL PRIMARY KEY,             
    service_name VARCHAR(100) NOT NULL,       
    description TEXT,                          
    price NUMERIC(10, 2) NOT NULL,            
    available BOOLEAN DEFAULT TRUE,           
    veterinarian_id INT NOT NULL,              
    veterinarian_first_name VARCHAR(100),      
    veterinarian_last_name VARCHAR(100),       
    FOREIGN KEY (veterinarian_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

ALTER TABLE services
ADD COLUMN service_time TIMESTAMP;  






--таблица записей не прием+
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id SERIAL PRIMARY KEY, 
    pet_id INT NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE, 
    service_id INT NOT NULL REFERENCES services(service_id),  
    appointment_date TIMESTAMP NOT NULL, 
    complaint TEXT,                      
    veterinarian_id INT NOT NULL REFERENCES employees(employee_id),  
    notes TEXT 
);

ALTER TABLE pets ADD COLUMN owner_last_name VARCHAR;




--таблица диагнозов+
CREATE TABLE IF NOT EXISTS diagnoses (
    diagnosis_id SERIAL PRIMARY KEY,                    
    pet_id INT NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE, 
    veterinarian_id INT NOT NULL REFERENCES employees(employee_id),
    diagnosis_date TIMESTAMP DEFAULT NOW(),            
    diagnosis_text TEXT NOT NULL,                       
    notes TEXT                                           
);

ALTER TABLE prescriptions
ADD COLUMN diagnosis_id INT REFERENCES diagnoses(diagnosis_id) ON DELETE CASCADE;



--таблица отзывов+
CREATE TABLE IF NOT EXISTS reviews (
    review_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES services(service_id) ON DELETE SET NULL,
    review_date TIMESTAMP DEFAULT NOW(),
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    review_text TEXT,
    response_text TEXT
);
ALTER TABLE reviews ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;



--таблица рецептов+
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE,
    veterinarian_id INT NOT NULL REFERENCES employees(employee_id),
    prescription_date TIMESTAMP DEFAULT NOW(),
    medication_name VARCHAR(150) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    administration_method VARCHAR(100),
    treatment_duration VARCHAR(50),
    notes TEXT
);




CREATE TABLE vet_service_mapping (
    position VARCHAR(255),       
    service_name VARCHAR(255)     
);

TRUNCATE TABLE vet_service_mapping;

drop table vet_service_mapping cascade;


INSERT INTO vet_service_mapping (position, service_name)
VALUES
    ('Ветеринарный терапевт', 'Консультация по общему состоянию здоровья животного'),
    ('Ветеринарный хирург', 'Хирургическое вмешательство при травмах'),
    ('Ветеринарный офтальмолог', 'Операции на глазах'),
    ('Ветеринарный кардиолог', 'Диагностика сердечно-сосудистых заболеваний');
   
   INSERT INTO vet_service_mapping (position, service_name)
VALUES
    ('Ветеринарный терапевт', 'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных'),
    ('Ветеринарный хирург', 'Удаление опухолей и новообразований'),
    ('Ветеринарный офтальмолог', 'Лечение глаукомы и катаракты у животных'),
    ('Ветеринарный кардиолог', 'Лечение сердечной недостаточности у домашних животных');

select count(*) from vet_service_mapping vsm ;
