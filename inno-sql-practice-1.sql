--the 1st query
SELECT   Count(fc.film_id) AS film_quantity,
         c."name"          AS category
FROM     category c
         LEFT JOIN film_category fc
         ON fc.category_id = c.category_id
GROUP BY c."name"
ORDER BY film_quantity DESC;

--the 2nd query
SELECT   a.first_name,
         a.last_name,
         Count(r.rental_id) AS rental_count
FROM     actor a
         JOIN film_actor fa
         ON fa.actor_id = a.actor_id
         JOIN inventory i
         ON i.film_id = fa.film_id
         JOIN rental r
         ON r.inventory_id = i.inventory_id
GROUP BY a.actor_id,
         a.first_name,
         a.last_name
ORDER BY rental_count DESC LIMIT 10;

--the 3rd query
SELECT   c."name",
         Sum(p.amount) AS "Sum"
FROM     category c
         JOIN film_category fc
         ON c.category_id = fc.category_id
         JOIN inventory i
         ON i.film_id = fc.film_id
         JOIN rental r
         ON i.inventory_id = r.inventory_id
         JOIN payment p
         ON p.rental_id = r.rental_id
GROUP BY c."name", c.category_id
ORDER BY "Sum" DESC;

--the 4th query (change to "WHERE NOT EXISTS")
SELECT f.title,
       f.film_id
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.film_id = f.film_id
);

-- the 5th query (added TOP 3 + group by  "a.actor_id")
WITH actor_films AS (
    SELECT
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS films_count,
        DENSE_RANK() OVER (
            ORDER BY COUNT(fa.film_id) DESC
        ) AS films_rank
    FROM actor a
    JOIN film_actor fa
        ON a.actor_id = fa.actor_id
    JOIN film_category fc
        ON fa.film_id = fc.film_id
    JOIN category c
        ON fc.category_id = c.category_id
    WHERE c."name" = 'Children'
    GROUP BY
	a.actor_id,
	a.first_name,
	a.last_name
)
SELECT
    first_name,
    last_name,
    films_count,
    films_rank
FROM actor_films
WHERE films_rank <= 3
ORDER BY
    films_count DESC,
    first_name,
    last_name;

--the 6th query
SELECT   ci.city,
         Count(*) FILTER (WHERE c.active = 1) AS active_count,
         Count(*) FILTER (WHERE c.active = 0) AS inactive_count
FROM     address a
         JOIN customer c
         ON a.address_id = c.address_id
         JOIN city ci
         ON a.city_id = ci.city_id
GROUP BY ci.city
ORDER BY inactive_count DESC;

--the 7th query
WITH city_cat AS (
    SELECT
        ci.city_id,
        ci.city,
        cat.name AS category,
        SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600) AS total_hours
    FROM rental r
    JOIN customer cu ON cu.customer_id = r.customer_id
    JOIN address a ON a.address_id = cu.address_id
    JOIN city ci ON ci.city_id = a.city_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category cat ON cat.category_id = fc.category_id
    GROUP BY ci.city_id, ci.city, cat.name
),
ranked AS (
        select *,
        RANK() OVER (PARTITION BY city_id ORDER BY total_hours DESC) AS rnk
    FROM city_cat
)
SELECT
    'The town starts with "a"' AS city_group,
    city,
    category,
    ROUND(total_hours::numeric, 1) AS total_hours
FROM ranked
WHERE rnk = 1
  AND LOWER(city) LIKE 'a%'
UNION ALL
SELECT
    'The town has "-"',
    city,
    category,
    ROUND(total_hours::numeric, 1)
FROM ranked
WHERE rnk = 1
  AND city LIKE '%-%'
ORDER BY city_group, city;

