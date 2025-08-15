import airflow
from airflow.utils.dates import days_ago
from airflow.providers.google.cloud.operators.cloud_run import CloudRunExecuteJobOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator

#from world_cup_qatar_elt_dbt.dag.settings import Settings

default_args = {
    'owner': 'airflow',
    'start_date': days_ago(1)
}

with airflow.DAG(
        'DBT_Taxitrip_data',
        default_args=default_args,
        schedule_interval=None
        ) as dag:
    execute_dbt_job = CloudRunExecuteJobOperator(
        task_id="execute_dbt_job",
        project_id='dataengineering-466011',
        region='us-central1',
        job_name='dbt-taxitrip-data',
        dag=dag,
        deferrable=False,
    )
    
execute_dbt_job