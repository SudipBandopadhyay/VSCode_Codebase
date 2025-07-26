
import functions_framework
from google.cloud import storage
import os
import pandas as pd
import io
import pyarrow.parquet as pq
import json
from google.cloud import bigquery

SMALL_FILE_THRESHOLD_MB = 10

# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def hello_gcs(cloud_event):
    data = cloud_event.data

    event_id = cloud_event["id"]
    event_type = cloud_event["type"]

    bucket = data["bucket"]
    file_name = data["name"]
    metageneration = data["metageneration"]
    timeCreated = data["timeCreated"]
    updated = data["updated"]

    gcs_path = f"gs://{bucket}/{file_name}"
    storage_client = storage.Client()
    blob = storage_client.bucket(bucket).get_blob(file_name)
    file_size_mb = blob.size / (1024 * 1024)

    print(f"Event ID: {event_id}")
    print(f"Event type: {event_type}")
    print(f"Bucket: {bucket}")
    print(f"File: {file_name}")
    print(f"Metageneration: {metageneration}")
    print(f"Created: {timeCreated}")
    print(f"Updated: {updated}")

    if already_processed(file_name):
        print(f"{file_name} has already been processed. Skipping.")
        return

    if file_size_mb < SMALL_FILE_THRESHOLD_MB:
        print(f"Small file detected ({file_size_mb:.2f} MB): {file_name}")
        process_small_file(bucket, file_name)
        #print(source_data.head(10))
    else:
        print(f"Large file detected ({file_size_mb:.2f} MB): {file_name}")
        #source_data = load_file_from_gcs(bucket,file_name)
        #print(source_data.head(10))
    
def detect_file_type(file_name):
    if file_name.endswith(".csv"):
        return "csv"
    elif file_name.endswith(".json"):
        return "json"
    elif file_name.endswith(".parquet"):
        return "parquet"
    else:
        return "unsupported"


def load_file_from_gcs(bucket_name, file_name):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(file_name)
    content = blob.download_as_bytes()

    file_type = detect_file_type(file_name)

    if file_type == "csv":
        return pd.read_csv(io.BytesIO(content))
    elif file_type == "json":
        return pd.read_json(io.BytesIO(content), lines=True)  # for ndjson
    elif file_type == "parquet":
        return pd.read_parquet(io.BytesIO(content))
    else:
        raise ValueError(f"Unsupported file type: {file_name}")

def process_small_file(bucket_name, file_name):
    source_data = load_file_from_gcs(bucket_name,file_name)
    bq_client = bigquery.Client()
    table_id = "dataengineering-466011.titanic.titanic_data"

    job = bq_client.load_table_from_dataframe(source_data, table_id)
    job.result() 

    metrics = {
    'filename': file_name,
    'row_count': len(source_data),
    #'validation_passed': len(errors) == 0,
    #'errors': str(errors),
    'processed_at': pd.Timestamp.now()
    }

    metrics_df = pd.DataFrame([metrics])
    bq_client.load_table_from_dataframe(metrics_df, "dataengineering-466011.titanic.audit_logs").result()


def already_processed(file_name):
    client = bigquery.Client()
    query = f"""
        SELECT 1 FROM `dataengineering-466011.titanic.audit_logs`
        WHERE filename = @file_name
        LIMIT 1
    """
    job = client.query(query, job_config=bigquery.QueryJobConfig(
        query_parameters=[bigquery.ScalarQueryParameter("file_name", "STRING", file_name)]
    ))
    return job.result().total_rows > 0
    




