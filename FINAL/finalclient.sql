--клиент
SELECT * FROM client_pets_view;
SELECT * FROM available_services;
SELECT * FROM view_appointments;
select * from client_diagnoses;
SELECT * FROM client_reviews_view;
SELECT * FROM employees_view;
select * from client_prescriptions_view;



CALL add_pet('няшка', 'Собака', 'Лабрадор', '2015-06-15');
CALL update_pet_for_client('няшка', null , 'Собака', 'Немецкая овчарка', '2013-12-10');
CALL delete_pet_for_client('qяшка');

call book_appointment_for_client('няшка', 'Диагностика сердечно-сосудистых заболеваний', '2024-12-29 13:00:00', 'Жалоба на усталость', 'Воронов');
call book_appointment_for_client('няшка', 'Принципиальная диагностика и лечение заболеваний дыхательной системы у животных', '2024-12-18 12:00:00.000', 'Жалоба на усталость', 'Бунинаэ');

CALL add_review_for_client('Принципиальная диагностика и лечение заболеваний дыхательной системы у животных', 'Бунинаэ', 5, 'Отличная плзо!', 'Ответ ветеринара: Всё хорошо.');

SELECT * FROM search_services('лечени');

  
SELECT * FROM sort_services('veterinarian_last_name', 'ASC');
SELECT * FROM sort_services('veterinarian_last_name', 'DESC');

SELECT * FROM sort_services('price', 'ASC');
SELECT * FROM sort_services('price', 'DESC');

