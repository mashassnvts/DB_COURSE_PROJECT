select * from reviews r ;

INSERT INTO reviews (client_id, service_id, review_date, rating, review_text, response_text)
SELECT 
    (SELECT client_id FROM clients ORDER BY RANDOM() LIMIT 1),  
    (SELECT service_id FROM services ORDER BY RANDOM() LIMIT 1), 
    NOW(),  
    FLOOR(RANDOM() * 5 + 1),  
    md5(RANDOM()::TEXT), 
    CASE 
        WHEN RANDOM() > 0.5 THEN md5(RANDOM()::TEXT) ELSE NULL 
    END 
FROM generate_series(1, 100000); 

select count(*) from reviews r; 


EXPLAIN ANALYZE 
SELECT * 
FROM reviews 
WHERE rating = 1
ORDER BY review_date DESC;

CREATE INDEX idx_reviews_rating ON reviews (rating);
CREATE INDEX idx_reviews_review_date ON reviews (review_date DESC);

EXPLAIN ANALYZE 
SELECT * 
FROM reviews 
WHERE rating = 1
ORDER BY review_date DESC;


DROP INDEX IF EXISTS idx_reviews_rating;
DROP INDEX IF EXISTS idx_reviews_review_date;