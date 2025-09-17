CREATE OR REPLACE TABLE lexis_nexis_task.exchange_rates_landing (
  record_id STRING OPTIONS(description="UUID assigned at ingestion"),
  source STRING,
  base_currency STRING,
  quote_currency STRING,
  rate NUMERIC,
  rate_date DATE,
  retrieved_at TIMESTAMP,
  raw_hash STRING,
  raw_payload STRING,                  -- JSON string; use STRING to avoid nested fields, or JSON type if available
  ingest_job_id STRING,
  created_at TIMESTAMP
)
PARTITION BY rate_date
CLUSTER BY ingest_job_id,base_currency, quote_currency, source
OPTIONS (
  partition_expiration_days = 10)---Automated partition expiry for purging old records
  ;

CREATE OR REPLACE TABLE lexis_nexis_task.exchange_rates (
  ecb_api_record_id STRING OPTIONS(description="UUID assigned at ingestion"),
  exchangerates_api_record_id STRING OPTIONS(description="UUID assigned at ingestion"),
  base_currency STRING,
  quote_currency STRING,
  rate_date DATE,
  ecb_api_rate NUMERIC,
  exchangerates_api_rates NUMERIC,
  ecb_api_retrieved_at TIMESTAMP,
  exchangerates_api_retrieved_at TIMESTAMP,
  ingest_job_id STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
PARTITION BY rate_date
CLUSTER BY ingest_job_id,base_currency, quote_currency
OPTIONS (
  partition_expiration_days = 30);---Automated partition expiry for purging old records




MERGE INTO
  lexis_nexis_task.exchange_rates t
USING
  (
  WITH
    exchangerates_api AS (
    SELECT
      *
    FROM
      lexis_nexis_task.exchange_rates_landing
    WHERE
      SOURCE='ExchangeRates_API'),
    ecb_api AS (
    SELECT
      *
    FROM
      lexis_nexis_task.exchange_rates_landing
    WHERE
      SOURCE='ECB_API')
  SELECT distinct
    ecb_api.record_id AS ecb_api_record_id,
    exchangerates_api.record_id AS exchangerates_api_record_id,
    IFNULL(ecb_api.base_currency, exchangerates_api.base_currency) AS base_currency,
    IFNULL(ecb_api.quote_currency, exchangerates_api.quote_currency) AS quote_currency,
    IFNULL(ecb_api.rate_date, exchangerates_api.rate_date) AS rate_date,
    ecb_api.rate AS ecb_api_rate,
    exchangerates_api.rate AS exchangerates_api_rates,
    ecb_api.retrieved_at AS ecb_api_retrieved_at,
    exchangerates_api.retrieved_at AS exchangerates_api_retrieved_at,
    IFNULL(ecb_api.ingest_job_id, exchangerates_api.ingest_job_id) AS ingest_job_id,
    CURRENT_TIMESTAMP() AS created_at
  FROM
    ecb_api
  FULL JOIN
    exchangerates_api
  ON
    ecb_api.ingest_job_id = exchangerates_api.ingest_job_id
    AND ecb_api.base_currency = exchangerates_api.base_currency
    AND ecb_api.quote_currency = exchangerates_api.quote_currency
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ecb_api.base_currency, ecb_api.quote_currency ORDER BY ecb_api.created_at DESC, exchangerates_api.created_at DESC) = 1
 ) s
ON
  s.base_currency = t.base_currency
  AND s.quote_currency = t.quote_currency
  AND s.rate_date = t.rate_date
  WHEN MATCHED AND (s.ecb_api_rate <> t.ecb_api_rate OR s.exchangerates_api_rates <> t.exchangerates_api_rates) THEN UPDATE SET t.ecb_api_record_id=s.ecb_api_record_id, t.exchangerates_api_record_id=s.exchangerates_api_record_id, t.ecb_api_rate=s.ecb_api_rate, t.exchangerates_api_rates=s.exchangerates_api_rates, t.ecb_api_retrieved_at=s.ecb_api_retrieved_at, t.exchangerates_api_retrieved_at = s.exchangerates_api_retrieved_at, t.ingest_job_id = s.ingest_job_id, t.updated_at = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED
  THEN
INSERT
  (ecb_api_record_id,
    exchangerates_api_record_id,
    base_currency,
    quote_currency,
    rate_date,
    ecb_api_rate,
    exchangerates_api_rates,
    ecb_api_retrieved_at,
    exchangerates_api_retrieved_at,
    ingest_job_id,
    created_at )
VALUES
  (ecb_api_record_id, exchangerates_api_record_id, base_currency, quote_currency, rate_date, ecb_api_rate, exchangerates_api_rates, ecb_api_retrieved_at, exchangerates_api_retrieved_at, ingest_job_id, created_at );


----------Function to get exchange rate for any source and target currency

CREATE OR REPLACE TABLE FUNCTION `lexis_nexis_task.get_exchange_rate`(
  source_currency STRING,
  target_currency STRING
)
AS
  WITH
    src AS (
      SELECT ecb_api_rate, exchangerates_api_rates, rate_date
      FROM `lexis_nexis_task.exchange_rates`
      WHERE quote_currency = source_currency
      QUALIFY ROW_NUMBER() OVER (PARTITION BY quote_currency ORDER BY rate_date DESC) = 1
    ),
    tgt AS (
      SELECT ecb_api_rate, exchangerates_api_rates, rate_date
      FROM `lexis_nexis_task.exchange_rates`
      WHERE quote_currency = target_currency
      QUALIFY ROW_NUMBER() OVER (PARTITION BY quote_currency ORDER BY rate_date DESC) = 1
    )
  SELECT
    source_currency AS src_currency,
    target_currency AS tgt_currency,
    tgt.ecb_api_rate / src.ecb_api_rate AS ecb_exchange_rate,
    tgt.exchangerates_api_rates / src.exchangerates_api_rates AS exchangerates_exchange_rate,
    src.rate_date AS src_rate_date,
    tgt.rate_date AS tgt_rate_date
  FROM src
  CROSS JOIN tgt;

-----Sample query to call the function
SELECT *
FROM `lexis_nexis_task.get_exchange_rate`("USD", "INR");


--- Converted currency for any source and target currency from latest data and preferred exchange rate source API

CREATE OR REPLACE FUNCTION lexis_nexis_task.convert_currency(
  source_currency STRING,
  target_currency STRING,
  exchange_rate_source STRING, -- Accepted values are ('ECB', 'ExchangeRate')
  amount FLOAT64
)
RETURNS STRING
AS (
  (
    WITH rates AS (
      SELECT *
      FROM `lexis_nexis_task.get_exchange_rate`(source_currency, target_currency)
    )
    SELECT
      CASE
        WHEN exchange_rate_source = 'ECB'
          THEN IFNULL(CAST(ecb_exchange_rate * amount AS STRING), 'Not Found')
        WHEN exchange_rate_source = 'ExchangeRate'
          THEN IFNULL(CAST(exchangerates_exchange_rate * amount AS STRING), 'Not Found')
        ELSE 'Not Found'
      END
    FROM rates
  )
);

-----Sample query to call the function
SELECT `lexis_nexis_task.convert_currency`("USD", "INR", "ECB", 100) AS converted;


-------Historical data for 90 days
SELECT rate_date, ecb_api_rate,exchangerates_api_rates
FROM lexis_nexis_task.exchange_rates
WHERE base_currency='EUR' AND quote_currency='USD'
  AND rate_date >= current_date - interval 90 day
ORDER BY rate_date;