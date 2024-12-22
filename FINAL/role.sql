-- Создание ролей без наследования
CREATE ROLE admin_role NOINHERIT;
CREATE ROLE employee_role NOINHERIT;
CREATE ROLE client_role NOINHERIT;

-- Администратор
CREATE USER admin_user WITH PASSWORD 'admin';
GRANT admin_role TO admin_user;

-- Привилегии для администратора
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin_role;
GRANT EXECUTE ON FUNCTION add_user(VARCHAR, TEXT, VARCHAR) TO admin_role;
GRANT EXECUTE ON FUNCTION update_user(INT, VARCHAR, TEXT, VARCHAR) TO admin_role;
GRANT EXECUTE ON FUNCTION delete_user(INT) TO admin_role;

-- Сотрудник
CREATE USER employee_user WITH PASSWORD 'Employee12345';
GRANT employee_role TO employee_user;

-- Привилегии для сотрудника
GRANT SELECT, INSERT, UPDATE ON employees TO employee_role;
GRANT SELECT, INSERT, UPDATE ON services TO employee_role;
GRANT SELECT ON pets, clients, appointments TO employee_role;
GRANT EXECUTE ON PROCEDURE update_employee_for_employee TO employee_role;
GRANT SELECT ON vet_view, employee_reviews_view TO employee_role;
GRANT INSERT, UPDATE, DELETE ON diagnoses, prescriptions TO employee_role;
GRANT EXECUTE ON PROCEDURE add_own_diagnosis_for_employee TO employee_user;
GRANT EXECUTE ON PROCEDURE update_own_diagnosis_for_employee TO employee_user;

-- Клиент
CREATE USER client_user WITH PASSWORD 'Client12345';
GRANT client_role TO client_user;

-- Привилегии для клиента
GRANT SELECT ON client_pets, available_services, client_appointments TO client_role;
GRANT INSERT, SELECT, UPDATE ON client_reviews TO client_role;
GRANT EXECUTE ON PROCEDURE add_pet, update_pet, delete_pet_by_name TO client_role;
GRANT EXECUTE ON FUNCTION book_appointment_for_client TO client_role;
GRANT SELECT ON client_user_view, vet_service_mapping TO client_role;

-- Управление привилегиями
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM client_role;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM client_role;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM client_role;

-- Проверка и удаление пользователей и ролей
DROP USER IF EXISTS admin_user, employee_user, client_user CASCADE;
DROP ROLE IF EXISTS admin_role, employee_role, client_role CASCADE;
