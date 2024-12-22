-----сотрудник
SELECT * FROM employee_view;
select * from employees_clients_view;
SELECT * FROM employees_pets_view;
SELECT * FROM all_services;
SELECT * FROM available_services;
SELECT * 
FROM all_services 
WHERE veterinarian_last_name = 'Бунинаэ';
SELECT s.*
FROM services s
JOIN vet_service_mapping vsm ON s.service_name = vsm.service_name
WHERE vsm.position = 'Ветеринарный терапевт';

SELECT * FROM appointment_details;


CALL update_employee_for_employee('Полина', 'Бунина', 'Ветеринарный терапевт');

CALL update_employee_for_employee(
   'Ветеринарный терапевт'
);


CALL add_service_for_employee(
    'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных',  
    500,  
    '2024-12-18 11:00:00',  
    'Консультация по состоянию здоровья животных. Проводится ветеринаром терапевтом.',  
    TRUE  
);


CALL add_service_for_employee(
    'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных',  
    500,  
    '2024-12-18 11:00:00',  
    'Консультация по состоянию здоровья животных. Проводится ветеринаром терапевтом.',  
    TRUE  
);


CALL add_service_for_employee(
    'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных',  
    500,  
    '2024-12-18 12:00:00',  
    'Консультация по состоянию здоровья животных. Проводится ветеринаром терапевтом.',  
    TRUE  
);



CALL update_service_for_employee(
    35,  
    'Консультация по общему состоянию здоровья животного', 
    400,         
    '2024-12-21 14:00:00', 
    'Обновленное описание услуги.',
    TRUE 
);


CALL delete_service_for_employee(35);  

SELECT * FROM all_services WHERE service_id = 28; 



SELECT * FROM appointment_details WHERE veterinarian_last_name = 'Бунинаэ';

CALL add_own_diagnosis_for_employee(
    'няшка',         
    'Диагноз: ОРЗ',     
    'Примечание: требует дальнейшего наблюдения' 
);

SELECT * FROM my_diagnoses;



CALL update_own_diagnosis_for_employee(
   'няшка',          
    'Диагноз: ОРЗ',  
    'Рекомендуется провести дополнительные тесты на вирусные инфекции' 
);


-- Врач удаляет диагноз для питомца "Барсик"
CALL delete_own_diagnosis_for_employee(
    'собакен'  -- Имя питомца
);



SELECT * FROM all_reviews_view;

CALL add_own_prescription(
    'няшка', 
    'Антибиотик', 
    '500 мг', 
    'Перорально', 
    '7 дней', 
    'Давать после еды'
);
SELECT * FROM employee_prescriptions_view;

CALL delete_own_prescription('собакен', 
    'Антибиотик');
   
   
   SELECT * FROM search_services('терапевтом');

