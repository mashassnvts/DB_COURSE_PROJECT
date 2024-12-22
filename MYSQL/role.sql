--role
-- Создание пользователей для администратора, сотрудника и клиента
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'Masha2004)';
CREATE USER 'employee_user'@'%' IDENTIFIED BY 'Example12)';
CREATE USER 'client_user'@'%' IDENTIFIED BY 'Pass123)';

-- Назначение привилегий для администратора
GRANT ALL PRIVILEGES ON `course`.* TO 'admin_user'@'%';

-- Назначение привилегий для сотрудника
GRANT SELECT, INSERT, UPDATE ON `course`.`employees` TO 'employee_user'@'%';
GRANT SELECT, INSERT, UPDATE ON `course`.`services` TO 'employee_user'@'%';
GRANT SELECT, INSERT, UPDATE ON `course`.`appointments` TO 'employee_user'@'%';
GRANT SELECT ON `course`.`pets` TO 'employee_user'@'%';
GRANT SELECT ON `course`.`diagnoses` TO 'employee_user'@'%';
GRANT SELECT, INSERT, UPDATE ON `course`.`prescriptions` TO 'employee_user'@'%';
GRANT SELECT ON `course`.`reviews` TO 'employee_user'@'%';

-- Привилегии для сотрудника на выполнение процедур
GRANT EXECUTE ON PROCEDURE `course`.`add_service_for_employee` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`update_service_for_employee` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`delete_service_for_employee` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`add_own_diagnosis_for_employee` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`update_own_diagnosis_for_employee` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`delete_own_diagnosis_for_employee` TO 'employee_user'@'%';

-- Привилегии для сотрудника на доступ к личным данным и выполнение определённых действий
GRANT SELECT, UPDATE ON `course`.`pets` TO 'employee_user'@'%';
GRANT SELECT, UPDATE ON `course`.`clients` TO 'employee_user'@'%';
GRANT SELECT, UPDATE ON `course`.`appointments` TO 'employee_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`add_pet_to_appointment` TO 'employee_user'@'%';

-- Назначение привилегий для клиента
GRANT SELECT ON `course`.`clients` TO 'client_user'@'%';
GRANT SELECT ON `course`.`pets` TO 'client_user'@'%';
GRANT SELECT ON `course`.`appointments` TO 'client_user'@'%';
GRANT SELECT ON `course`.`services` TO 'client_user'@'%';
GRANT SELECT ON `course`.`reviews` TO 'client_user'@'%';
GRANT SELECT ON `course`.`diagnoses` TO 'client_user'@'%';
GRANT SELECT ON `course`.`prescriptions` TO 'client_user'@'%';

-- Привилегии для клиента на доступ к представлениям
GRANT SELECT ON `course`.`client_pets_view` TO 'client_user'@'%';
GRANT SELECT ON `course`.`client_appointments_view` TO 'client_user'@'%';
GRANT SELECT ON `course`.`client_reviews_view` TO 'client_user'@'%';
GRANT SELECT ON `course`.`client_prescriptions_view` TO 'client_user'@'%';

-- Привилегии для клиента на выполнение процедур, связанных с его питомцами
GRANT EXECUTE ON PROCEDURE `course`.`add_pet` TO 'client_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`update_pet` TO 'client_user'@'%';
GRANT EXECUTE ON PROCEDURE `course`.`delete_pet` TO 'client_user'@'%';

-- Привилегии для клиента на добавление, изменение и удаление отзывов
GRANT EXECUTE ON PROCEDURE `course`.`add_review_for_client` TO 'client_user'@'%';
GRANT INSERT, UPDATE ON `course`.`reviews` TO 'client_user'@'%';

-- Привилегии для клиента на запись на приём
GRANT SELECT ON `course`.`available_services` TO 'client_user'@'%';
GRANT EXECUTE ON FUNCTION `course`.`book_appointment_for_client` TO 'client_user'@'%';

-- Удаление пользователей, если они больше не нужны
DROP USER IF EXISTS 'client_user'@'%';
DROP USER IF EXISTS 'employee_user'@'%';
DROP USER IF EXISTS 'admin_user'@'%';
