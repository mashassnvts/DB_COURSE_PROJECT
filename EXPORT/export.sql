CREATE OR REPLACE FUNCTION export_reviews_to_json(p_export_path text) 
RETURNS VOID 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
    json_text text; 
BEGIN 
    SELECT json_agg(row_to_json(reviews))::text INTO json_text FROM reviews; 
    
    EXECUTE 'COPY (SELECT ' || quote_literal(json_text) || '::text) TO ''' || p_export_path || ''' WITH (FORMAT text)'; 
END; 
$$;


SELECT export_reviews_to_json('D:/masha/university/course/data.json');