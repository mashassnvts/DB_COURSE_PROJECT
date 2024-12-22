CREATE OR REPLACE PROCEDURE import_reviews_from_json(p_file_path text) 
LANGUAGE plpgsql 
AS $$ 
BEGIN
    CREATE TEMP TABLE temp_reviews (data json); 
    
    EXECUTE format('COPY temp_reviews FROM %L', p_file_path);
    
    INSERT INTO reviews (client_id, service_id, review_date, rating, review_text, response_text)
    SELECT 
        (value->>'client_id')::int AS client_id,
        (value->>'service_id')::int AS service_id,
        (value->>'review_date')::timestamp AS review_date,
        (value->>'rating')::int AS rating,
        value->>'review_text' AS review_text,
        value->>'response_text' AS response_text
    FROM temp_reviews, json_array_elements(data) AS value; 

    DROP TABLE IF EXISTS temp_reviews; 
END; 
$$;



CALL import_reviews_from_json('D:/masha/university/course/data.json');