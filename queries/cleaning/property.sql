UPDATE raw_property SET sqft = REPLACE(sqft, ',', '');
UPDATE raw_property SET hlfbath = 0 WHERE hlfbath IS NULL;
DELETE FROM raw_property WHERE lati IS NULL;
DELETE FROM raw_property WHERE longi IS NULL;
DELETE FROM raw_property WHERE bath IS NULL;
DELETE FROM raW_property WHERE sqft = '';

INSERT INTO property (type, bedrooms, bathrooms, garage, square_feet, price, latitude, longitude)
    SELECT type, bed, bath*1.0+(hlfbath*0.5), 0, CAST(sqft as FLOAT), price, lati, longi FROM raw_property;