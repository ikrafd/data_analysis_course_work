USE storeSite
GO
DELETE FROM storeSite.stageArea.click_stream;
BULK INSERT storeSite.stageArea.click_stream
FROM 'D:\uni\AD\dataset\click_stream.csv'
WITH ( format ='CSV',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a',
	FIRSTROW = 2
);

USE storeSite
GO
UPDATE stageArea.click_stream
SET event_metadata = REPLACE(event_metadata, '''', '"');

USE storeSite
GO
BULK INSERT storeSite.stageArea.customer
FROM 'D:\uni\AD\dataset\customer.csv'
WITH ( 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a',
	DATAFILETYPE = 'char',
	FIRSTROW = 2
);

BULK INSERT storeSite.stageArea.product
FROM 'D:\uni\AD\dataset\output_file.csv'
WITH ( format ='CSV',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a',
	FIRSTROW = 2
);

BULK INSERT storeSite.stageArea.transactions
FROM 'D:\uni\AD\dataset\transaction_new.csv'
WITH ( format ='CSV',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a',
	FIRSTROW = 2
);

