USE storeSite
GO

UPDATE stageArea.product
SET usage = 'N/A'
WHERE usage = 'Not Applicable'

UPDATE stageArea.product
SET season = 'N/A'
WHERE season is null

UPDATE stageArea.product
SET yearReg =  -1
WHERE yearReg is null

-- time
delete from warehouse.dim_time
DBCC CHECKIDENT ('warehouse.dim_time', RESEED, 1);
INSERT INTO warehouse.dim_time
SELECT DISTINCT
    YEAR(st.created_at) AS [Year],
    MONTH(st.created_at) AS [Month],
    DAY(st.created_at) AS [Day]
FROM 
    stageArea.transactions AS st
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse.dim_time AS dt
    WHERE YEAR(st.created_at) = dt.[Year]
          AND MONTH(st.created_at) = dt.[Month]
          AND DAY(st.created_at) = dt.[Day]
)

INSERT INTO warehouse.dim_time
SELECT DISTINCT
    YEAR(st.shipment_date_limit) AS [Year],
    MONTH(st.shipment_date_limit) AS [Month],
    DAY(st.shipment_date_limit) AS [Day]
FROM 
    stageArea.transactions AS st
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse.dim_time AS dt
    WHERE YEAR(st.created_at) = dt.[Year]
          AND MONTH(st.created_at) = dt.[Month]
          AND DAY(st.created_at) = dt.[Day]
)

INSERT INTO warehouse.dim_time
SELECT DISTINCT
    YEAR(sc.event_time) AS [Year],
    MONTH(sc.event_time) AS [Month],
    DAY(sc.event_time) AS [Day]
	from stageArea.click_stream AS sc
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse.dim_time AS dt
    WHERE YEAR(sc.event_time) = dt.[Year]
          AND MONTH(sc.event_time) = dt.[Month]
          AND DAY(sc.event_time) = dt.[Day]
)

INSERT INTO warehouse.dim_time
SELECT DISTINCT
    YEAR(sc.birthdate) AS [Year],
    MONTH(sc.birthdate) AS [Month],
    DAY(sc.birthdate) AS [Day]
	from stageArea.customer AS sc
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse.dim_time AS dt
    WHERE YEAR(sc.birthdate) = dt.[Year]
          AND MONTH(sc.birthdate) = dt.[Month]
          AND DAY(sc.birthdate) = dt.[Day]
)

INSERT INTO warehouse.dim_time
SELECT DISTINCT
    YEAR(sc.first_join_date) AS [Year],
    MONTH(sc.first_join_date) AS [Month],
    DAY(sc.first_join_date) AS [Day]
	from stageArea.customer AS sc
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse.dim_time AS dt
    WHERE YEAR(sc.first_join_date) = dt.[Year]
          AND MONTH(sc.first_join_date) = dt.[Month]
          AND DAY(sc.first_join_date) = dt.[Day])

-- event_name
INSERT INTO warehouse.dim_event_name
SELECT DISTINCT event_name
FROM stageArea.click_stream as SC
WHERE SC.event_name NOT IN (SELECT event_name_value FROM warehouse.dim_event_name);

-- attributes
delete from warehouse.dim_attributes;
DBCC CHECKIDENT ('warehouse.dim_attributes', RESEED, 1);

WITH ExtractedValues AS (
    SELECT DISTINCT 
    DEN.event_name_id as id,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.product_id'), '') AS product_id,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.quantity'), '') AS quantity,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.item_price'), '') AS item_price,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.payment_status'), '') AS payment_status,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.search_keywords'), '') AS search_keywords,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.promo_code'), '') AS promo_code,
    ISNULL(JSON_VALUE(SC.event_metadata, '$.promo_amount'), '') AS promo_amount 
FROM stageArea.click_stream AS SC
LEFT JOIN warehouse.dim_event_name AS DEN ON SC.event_name = DEN.event_name_value
) 
INSERT INTO warehouse.dim_attributes
SELECT DISTINCT 
    EV.id,
    EV.product_id,
    EV.quantity,
    EV.item_price,
    EV.payment_status,
    EV.promo_code,
    EV.promo_amount,
    EV.search_keywords
FROM ExtractedValues AS EV
WHERE EV.product_id NOT IN (SELECT product_id FROM warehouse.dim_attributes)
  AND EV.quantity NOT IN (SELECT quantity FROM warehouse.dim_attributes)
  AND EV.item_price NOT IN (SELECT item_price FROM warehouse.dim_attributes)
  AND EV.payment_status NOT IN (SELECT payment_status FROM warehouse.dim_attributes)
  AND EV.search_keywords NOT IN (SELECT search_keywords FROM warehouse.dim_attributes)
  AND EV.promo_code NOT IN (SELECT promo_code FROM warehouse.dim_attributes)
  AND EV.promo_amount NOT IN (SELECT promo_amount FROM warehouse.dim_attributes);

-- device_type
INSERT INTO warehouse.dim_device_type
SELECT DISTINCT device_type
FROM stageArea.customer as SC
WHERE SC.device_type NOT IN (SELECT dev_type_name FROM warehouse.dim_device_type);

-- device_version
INSERT INTO warehouse.dim_device_version
SELECT DISTINCT device_version
FROM stageArea.customer as SC
WHERE SC.device_version NOT IN (SELECT version_name FROM warehouse.dim_device_version);

-- town
INSERT INTO warehouse.dim_town
SELECT DISTINCT home_location
FROM stageArea.customer as SC
WHERE SC.home_location NOT IN (SELECT town_name FROM warehouse.dim_town);

-- home
INSERT INTO warehouse.dim_home
SELECT DISTINCT sc.home_location_lat, sc.home_location_long, T.town_id, sc.home_country
FROM stageArea.customer as SC
LEFT JOIN warehouse.dim_town AS T ON SC.home_location = T.town_name
WHERE SC.device_version NOT IN (SELECT version_name FROM warehouse.dim_device_version);

-- customer
DBCC CHECKIDENT ('warehouse.dim_customer', RESEED, 1);
INSERT INTO warehouse.dim_customer
SELECT DISTINCT sc.customer_id, sc.first_name, sc.last_name, sc.username, sc.email, sc.gender,  
				dt.dev_type_id, sc.device_id, dv.version_id, h.home_id, null, tb.time_id, ti.time_id
FROM stageArea.customer as SC
LEFT JOIN warehouse.dim_device_type AS DT ON SC.device_type = DT.dev_type_name
LEFT JOIN warehouse.dim_device_version AS DV ON SC.device_version = DV.version_name
LEFT JOIN warehouse.dim_town AS T ON SC.home_location = T.town_name
LEFT JOIN warehouse.dim_home AS H ON sc.home_location_lat = h.home_location_lat AND sc.home_location_long =h.home_location_long AND sc.home_location = T.town_name and h.home_location = t.town_id
LEFT JOIN warehouse.dim_time AS ti ON year(sc.first_join_date) = ti.[year] and month(sc.first_join_date) = ti.[month] and day(sc.first_join_date) = ti.[day]
LEFT JOIN warehouse.dim_time AS tb ON year(sc.birthdate) = tb.[year] and month(sc.birthdate) = tb.[month] and day(sc.birthdate) = tb.[day]
where sc.customer_id not in (select customer_id from  warehouse.dim_customer)

-- articleType
INSERT INTO warehouse.dim_articleType
SELECT DISTINCT articleType
FROM stageArea.product as SP
WHERE SP.articleType NOT IN (SELECT articleType_name FROM warehouse.dim_articleType);

-- baseColour
INSERT INTO warehouse.dim_baseColour
SELECT DISTINCT baseColour
FROM stageArea.product as SP
WHERE SP.baseColour NOT IN (SELECT baseColour_name FROM warehouse.dim_baseColour);

-- gender
INSERT INTO warehouse.dim_gender
SELECT DISTINCT gender
FROM stageArea.product as SP
WHERE Sp.gender NOT IN (SELECT gender_name FROM warehouse.dim_gender);

-- masterCategory
INSERT INTO warehouse.dim_masterCategory
SELECT DISTINCT masterCategory
FROM stageArea.product as SP
WHERE Sp.masterCategory NOT IN (SELECT masterCategory_name FROM warehouse.dim_masterCategory);

-- season
delete from warehouse.dim_season
INSERT INTO warehouse.dim_season
SELECT DISTINCT season
FROM stageArea.product as SP
WHERE sp.season NOT IN (SELECT season_name FROM warehouse.dim_season) and season is not null;

-- subCategory
INSERT INTO warehouse.dim_subCategory
SELECT DISTINCT subCategory
FROM stageArea.product as SP
WHERE Sp.subCategory NOT IN (SELECT subCategory_name FROM warehouse.dim_subCategory);

-- usage
delete from warehouse.dim_usage
INSERT INTO warehouse.dim_usage
SELECT DISTINCT usage
FROM stageArea.product as SP
WHERE sp.usage NOT IN (SELECT usage_name FROM warehouse.dim_usage) and usage is not null;

-- product
delete from warehouse.dim_product
DBCC CHECKIDENT ('warehouse.dim_product', RESEED, 1);
INSERT INTO warehouse.dim_product
SELECT DISTINCT top(10) sp.id, g.gender_id, mc.masterCategory_id, sc.subCategory_id, sat.articleType_id, 
	bc.baseColour_id, s.season_id, 
	sp.yearReg, u.usage_id, 
	sp.productDisplayName, null
FROM stageArea.product as SP
LEFT JOIN warehouse.dim_gender AS G ON SP.gender = g.gender_name
LEFT JOIN warehouse.dim_masterCategory AS MC ON sp.masterCategory = mc.masterCategory_name
LEFT JOIN warehouse.dim_subCategory AS SC ON sp.subCategory = sc.subCategory_name
LEFT JOIN warehouse.dim_articleType AS SAT ON sp.articleType = sat.articleType_name
LEFT JOIN warehouse.dim_baseColour AS BC ON sp.baseColour = bc.baseColour_name
LEFT JOIN warehouse.dim_season AS S ON sp.season = s.season_name
LEFT JOIN warehouse.dim_usage AS U ON sp.usage = u.usage_name 
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM warehouse.dim_product AS DP
        WHERE
			DP.id = SP.id AND
			DP.gender = G.gender_id AND
            DP.masterCategory = MC.masterCategory_id AND
            DP.subCategory = SC.subCategory_id AND
            DP.articleType = SAT.articleType_id AND
            DP.baseColour = BC.baseColour_id AND
            DP.season = S.season_id AND
            DP.yearReg = SP.yearReg AND
            DP.usage = U.usage_id AND
            DP.productDisplayName = SP.productDisplayName
    ) AND season IS NOT NULL and yearReg IS NOT NULL AND usage IS NOT NULL ;

-- тригер на product
CREATE TRIGGER warehouse.trg_CheckAndUpdateDimProduct
ON warehouse.dim_product
AFTER INSERT
AS
BEGIN
    DECLARE @id INT,
            @gender INT,
            @masterCategory INT,
            @subCategory INT,
            @articleType INT,
            @baseColour INT,
            @season INT,
            @yearReg INT,
            @usage INT,
            @productDisplayName NVARCHAR(255);

    SELECT 
        @id = SP.id, 
        @gender = G.gender_id, 
        @masterCategory = MC.masterCategory_id, 
        @subCategory = SC.subCategory_id, 
        @articleType = SAT.articleType_id, 
        @baseColour = BC.baseColour_id, 
        @season = S.season_id, 
        @yearReg = SP.yearReg, 
        @usage = U.usage_id, 
        @productDisplayName = SP.productDisplayName
    FROM 
        inserted AS SP
    LEFT JOIN warehouse.dim_gender AS G ON SP.gender = G.gender_name
    LEFT JOIN warehouse.dim_masterCategory AS MC ON SP.masterCategory = MC.masterCategory_name
    LEFT JOIN warehouse.dim_subCategory AS SC ON SP.subCategory = SC.subCategory_name
    LEFT JOIN warehouse.dim_articleType AS SAT ON SP.articleType = SAT.articleType_name
    LEFT JOIN warehouse.dim_baseColour AS BC ON SP.baseColour = BC.baseColour_name
    LEFT JOIN warehouse.dim_season AS S ON SP.season = S.season_name
    LEFT JOIN warehouse.dim_usage AS U ON SP.usage = U.usage_name;

    IF EXISTS (
        SELECT 1
        FROM warehouse.dim_product AS DP
        WHERE
            DP.id = @id AND
            DP.gender = @gender AND
            DP.masterCategory = @masterCategory AND
            DP.subCategory = @subCategory AND
            DP.articleType = @articleType AND
            DP.baseColour = @baseColour AND
            DP.season = @season AND
            DP.yearReg = @yearReg AND
            DP.usage = @usage AND
            DP.productDisplayName = @productDisplayName
    )
    BEGIN
        UPDATE warehouse.dim_product
        SET previous_id = @id
        WHERE id = @id;
    END;
END;

-- payment_method
INSERT INTO warehouse.dim_payment_method
SELECT DISTINCT payment_method
FROM stageArea.transactions as ST
WHERE st.payment_method NOT IN (SELECT method_name FROM warehouse.dim_payment_method);

-- payment_status
INSERT INTO warehouse.dim_payment_status
SELECT DISTINCT payment_status
FROM stageArea.transactions as ST
WHERE st.payment_status NOT IN (SELECT status_name FROM warehouse.dim_payment_status);

-- promo_code
INSERT INTO warehouse.dim_promo_code
SELECT DISTINCT promo_code, null
FROM stageArea.transactions as ST
WHERE st.promo_code NOT IN (SELECT code_name FROM warehouse.dim_promo_code) and promo_code is not null;

-- traffic_source
INSERT INTO warehouse.dim_traffic_source
SELECT DISTINCT traffic_source
FROM stageArea.click_stream as SC
WHERE SC.traffic_source NOT IN (SELECT traffic_name FROM warehouse.dim_traffic_source);

-- fact_click_stream
delete from  warehouse.fact_click_stream
INSERT INTO 
    warehouse.fact_click_stream
SELECT DISTINCT  event_id, session_id_, a.event_data_id, t.time_id, ts.traffic_id, CAST(sc.event_time AS time)
FROM stageArea.click_stream as sc
join warehouse.dim_event_name as n on sc.event_name= n.event_name_value
join warehouse.dim_attributes as a on a.event_name = n.event_name_id
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.product_id'), '') = a.product_id 
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.quantity'), '') = a.quantity
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.payment_status'), '') = a.[payment_status]
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.promo_code'), '') = a.promo_code
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.promo_amount'), '') = a.promo_amount
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.search_keywords'), '') = a.search_keywords
	and ISNULL(JSON_VALUE(SC.event_metadata, '$.item_price'), '') = a.item_price
join warehouse.dim_time as t on DATEFROMPARTS(YEAR(sc.event_time), MONTH(sc.event_time), DAY(sc.event_time)) = DATEFROMPARTS(t.[year], t.[month], t.[day])
join warehouse.dim_traffic_source as ts on sc.traffic_source = ts.traffic_name
where event_id not in (select event_id from warehouse.fact_click_stream)

-- fact_transactions
INSERT INTO warehouse.fact_transactions
SELECT DISTINCT st.booking_id, t.time_id, c.customer_key, st.session_id_, pm.method_id, ps.status_id, st.promo_amount, pc.code_key,
	st.shipment_fee, ti.time_id, st.shipment_location_lat, st.shipment_location_long, st.total_amount, CAST(st.shipment_date_limit AS time), CAST(st.created_at AS time)
FROM stageArea.transactions as st
LEFT JOIN warehouse.dim_customer AS c ON st.customer_id = c.customer_id 
LEFT JOIN warehouse.dim_payment_method AS pm ON st.payment_method = pm.method_name
LEFT JOIN warehouse.dim_payment_status AS ps ON st.payment_status= ps.status_name
LEFT JOIN warehouse.dim_promo_code AS pc ON st.promo_code = pc.code_name 
LEFT JOIN warehouse.dim_time AS T ON year(st.created_at) = t.[year] AND MONTH(st.created_at) = t.[month] AND day(st.created_at) = t.[day] 
LEFT JOIN warehouse.dim_time AS ti ON year(st.shipment_date_limit) = ti.[year]
	AND MONTH(st.shipment_date_limit) = ti.[month]
	AND day(st.shipment_date_limit) = ti.[day] 
WHERE St.booking_id NOT IN (SELECT booking_id FROM warehouse.fact_transactions);

-- transactions_product
DBCC CHECKIDENT ('warehouse.dim_transactions_product', RESEED, 1);
INSERT INTO warehouse.dim_transactions_product
SELECT t.booking_id, p.product_key, t.quantity, t.item_price
FROM stageArea.transactions as t
INNER JOIN warehouse.dim_product AS p ON t.product_id = p.id;
