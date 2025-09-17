import pandas as pd
import requests
import json
import os
import uuid
import hashlib
import logging
from datetime import datetime, date, timezone
from decimal import Decimal, ROUND_DOWN
import xml.etree.ElementTree as ET
from google.cloud import bigquery, secretmanager
import yaml
import sys
import pyarrow



def load_config(path="config.yaml"):
    with open(path, "r") as f:
        return yaml.safe_load(f)

# Usage
config = load_config()
gcp_project = config["project"]["id"]
bq_dataset = config["project"]["dataset"]
bq_final_table = config["tables"]["bq_final_table"]
bq_landing_table = config["tables"]["bq_landing_table"]
exchange_rates_url = config["sources"]["exchange_rates_url"]
ecb_url = config["sources"]["ecb_url"]
job_id = str(uuid.uuid4())

################### logging ###################

logging.basicConfig(
    filename="/tmp/exchange_rates_ingest.log",
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s: %(message)s"
)
logger = logging.getLogger("exchange_rates_ingest")

################### function to get secret from GCP Secret Manager ###################

def get_secret(secret_id: str, project_id: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

exchange_rates_api_key = get_secret("ExchangeRatesAPIKey", gcp_project)


################### function to parse exchangeratesapi ###################

def parse_exchangeratesapi(job_id: str) -> pd.DataFrame:
    try:
        r = requests.get(url=exchange_rates_url, params={"access_key": exchange_rates_api_key})
        r.raise_for_status()  # Raise an error for HTTP errors
    except requests.RequestException as e:
        print(f"Error fetching exchange rates: {e}")
        return pd.DataFrame()  # Return an empty DataFrame on error

    payload = r.json() # The JSON response from the API
    raw_json = json.dumps(payload, sort_keys=True) # Ensure consistent ordering
    raw_hash = hashlib.sha256(raw_json.encode("utf-8")).hexdigest() # Hash of the raw JSON payload
    rates = payload.get("rates", {}) # Dictionary of currency rates
    rate_date = payload.get("date")
    rows = []
    for quote, r in rates.items():  # Iterate over each currency and its rate
        rows.append({
            "record_id": str(uuid.uuid4()),
            "source": "ExchangeRates_API",
            "base_currency": 'EUR',
            "quote_currency": quote,
            "rate": float(r),
            "rate_date": pd.to_datetime(rate_date).date(),
            "retrieved_at": datetime.utcnow().isoformat(),
            "raw_hash": raw_hash,
            "raw_payload": raw_json,
            "ingest_job_id": job_id,
            "created_at": datetime.utcnow().isoformat()
        })
    logger.info(f"Parsed ExchangeRates API data successfully: {len(rows)} records found.")
    return pd.DataFrame(rows)


################### function to parse ECB XML ###################

def parse_ecb_api(job_id: str) -> pd.DataFrame:
    try:
        r = requests.get(ecb_url, timeout=30)
        r.raise_for_status()
    except requests.RequestException as e:
        print(f"Error fetching ECB data: {e}")
        return pd.DataFrame()
    ecb_data = r.text
    root = ET.fromstring(ecb_data) # Parse the XML
    raw_hash = hashlib.sha256(ecb_data.encode("utf-8")).hexdigest() # Hash of the raw XML payload
    rows = []
    # find Cube elements with time attr
    # namespace handling
    ns = {'ns': 'http://www.ecb.int/vocabulary/2002-08-01/eurofxref'}
    for cube_time in root.findall('.//{http://www.ecb.int/vocabulary/2002-08-01/eurofxref}Cube[@time]'):
        time_attr = cube_time.attrib['time']
        for cube in cube_time.findall('{http://www.ecb.int/vocabulary/2002-08-01/eurofxref}Cube'):
            cur = cube.attrib.get('currency')
            rate_str = cube.attrib.get('rate')
            if not (cur and rate_str):
                continue
            rows.append({
                "record_id": str(uuid.uuid4()),
                "source": "ECB_API",
                "base_currency": "EUR",
                "quote_currency": cur,
                "rate": float(rate_str),
                "rate_date": pd.to_datetime(time_attr).date(),
                "retrieved_at": datetime.utcnow().isoformat(),
                "raw_hash": raw_hash,
                "raw_payload": ecb_data,
                "ingest_job_id": job_id,
                "created_at": datetime.utcnow().isoformat()
            })
    logger.info(f"Parsed ECB data successfully: {len(rows)} records found.")
    return pd.DataFrame(rows)

################### function to convert numeric for BigQuery ###################

def to_numeric_bq(x):
    if pd.isnull(x):
        return None
    d = Decimal(str(x))
    # Round to 9 decimal places, truncate extra precision
    return d.quantize(Decimal("0.000000001"), rounding=ROUND_DOWN)


################### function for data validation    ###################


def validate_exchange_rates_data(df: pd.DataFrame) -> pd.DataFrame:

    currency_columns = ["base_currency", "quote_currency"]

    df = df.dropna() # Drop rows with any NULLs

    # Filter valid currency codes
    currency_columns = ["base_currency", "quote_currency"]
    mask = df[currency_columns].astype(str).apply(lambda col: col.str.match(r"^[A-Z]{3}$")).any(axis=1)
    df = df[mask] 

    df = df[df["rate"].apply(lambda x: isinstance(x, (int, float)) and x > 0)] # Filter valid rates

    df = df.drop_duplicates(keep="last") # Deduplicate

    return df

################### function to load data into BigQuery ###################


def write_to_bq(df: pd.DataFrame, client: bigquery.Client, job_id: str):

    landing_table_id = f"{gcp_project}.{bq_dataset}.{bq_landing_table}"

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND",
        schema=[
            bigquery.SchemaField("record_id", "STRING"),
            bigquery.SchemaField("source", "STRING"),
            bigquery.SchemaField("base_currency", "STRING"),
            bigquery.SchemaField("quote_currency", "STRING"),
            bigquery.SchemaField("rate", "NUMERIC"),
            bigquery.SchemaField("rate_date", "DATE"),
            bigquery.SchemaField("retrieved_at", "TIMESTAMP"),
            bigquery.SchemaField("raw_hash", "STRING"),
            bigquery.SchemaField("raw_payload", "STRING"),
            bigquery.SchemaField("ingest_job_id", "STRING"),
            bigquery.SchemaField("created_at", "TIMESTAMP"),
        ],
    )

    df_load = df[["record_id","source","base_currency","quote_currency","rate",
        "rate_date","retrieved_at","raw_hash","raw_payload",
        "ingest_job_id","created_at"
    ]].copy()

    # Convert columns to correct types
    df_load["rate_date"] = pd.to_datetime(df_load["rate_date"], errors="coerce").dt.date
    df_load["retrieved_at"] = pd.to_datetime(df_load["retrieved_at"])
    df_load["created_at"] = pd.to_datetime(df_load["created_at"])
    df_load["rate"] = df_load["rate"].apply(to_numeric_bq)   


    # Load to BigQuery
    load_job = client.load_table_from_dataframe(df_load, landing_table_id, job_config=job_config)
    load_job.result()
    print(f"✅ Loaded {load_job.output_rows} rows into {landing_table_id}")
    logger.info("Successfully loaded %s record into landing table %s", load_job.output_rows, landing_table_id)


    finaltable_id = f"{gcp_project}.{bq_dataset}.{bq_final_table}"

    final_table_query = f"""
    MERGE INTO `{finaltable_id}` t
    USING
    (
        WITH
            exchangerates_api AS 
            (
                SELECT
                *
                FROM `{landing_table_id}`
                WHERE source='ExchangeRates_API'
            ),
            ecb_api AS 
            (
                SELECT
                *
                FROM `{landing_table_id}`
                WHERE source='ECB_API'
            )
        SELECT
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
        FROM ecb_api
        FULL JOIN
            exchangerates_api
        ON
            ecb_api.ingest_job_id = exchangerates_api.ingest_job_id
            AND ecb_api.base_currency = exchangerates_api.base_currency
            AND ecb_api.quote_currency = exchangerates_api.quote_currency
        QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ecb_api.base_currency, ecb_api.quote_currency ORDER BY ecb_api.created_at DESC, exchangerates_api.created_at DESC) = 1
    ) s
    ON
        s.base_currency = t.base_currency
        AND s.quote_currency = t.quote_currency
        AND s.rate_date = t.rate_date
    WHEN MATCHED AND 
        (s.ecb_api_rate <> t.ecb_api_rate OR s.exchangerates_api_rates <> t.exchangerates_api_rates) 
    THEN UPDATE 
        SET 
        t.ecb_api_record_id=s.ecb_api_record_id, 
        t.exchangerates_api_record_id=s.exchangerates_api_record_id, 
        t.ecb_api_rate=s.ecb_api_rate, 
        t.exchangerates_api_rates=s.exchangerates_api_rates, 
        t.ecb_api_retrieved_at=s.ecb_api_retrieved_at, 
        t.exchangerates_api_retrieved_at = s.exchangerates_api_retrieved_at, 
        t.ingest_job_id = s.ingest_job_id, 
        t.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED
    THEN INSERT
    (
        ecb_api_record_id,
        exchangerates_api_record_id,
        base_currency,
        quote_currency,
        rate_date,
        ecb_api_rate,
        exchangerates_api_rates,
        ecb_api_retrieved_at,
        exchangerates_api_retrieved_at,
        ingest_job_id,
        created_at 
    )
    VALUES
    (
        ecb_api_record_id, 
        exchangerates_api_record_id, 
        base_currency, quote_currency, 
        rate_date, ecb_api_rate, 
        exchangerates_api_rates, 
        ecb_api_retrieved_at, 
        exchangerates_api_retrieved_at, 
        ingest_job_id, 
        created_at 
    )                        
    """

    query_job = client.query(final_table_query)
    query_job.result()

    print(f"✅ Merged {query_job.num_dml_affected_rows}  rows into {finaltable_id}")
    logger.info("Merge job successfully merged %s record into final table %s", query_job.num_dml_affected_rows, finaltable_id)


################### main function ###################

def main():
    client = bigquery.Client(project=gcp_project)
    job_id = str(uuid.uuid4())
    logger.info("Starting ingest job %s", job_id)

    # parse ExchangeRates API
    try:
        df_exch = parse_exchangeratesapi(job_id)
    except Exception as e:
        logger.exception("ExchangeRatesAPI fetch failed: %s", e)
        df_exch = pd.DataFrame()

    # parse ECB API
    try:
        df_ecb = parse_ecb_api(job_id)
    except Exception as e:
        logger.exception("ECB fetch failed: %s", e)
        df_ecb = pd.DataFrame()

    # Combine data from both sources
    df_all = pd.concat([df_exch, df_ecb], ignore_index=True) if not (df_exch.empty and df_ecb.empty) else pd.DataFrame()

    if df_all.empty:
        logger.info("No data collected; exiting")
        return
    
    # Validate
    df_final = validate_exchange_rates_data(df_all)

    # Upsert into BigQuery
    try:
        write_to_bq(df_final, client, job_id)
    except Exception as e:
        logger.exception("Data Load to Bigquery Failed: %s", e)
        df_ecb = pd.DataFrame()

    logger.info("Ingest job finished: %s", job_id)

if __name__ == "__main__":
    main()
