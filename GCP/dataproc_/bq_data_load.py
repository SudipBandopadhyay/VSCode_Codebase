
from pyspark.sql import SparkSession
#import zipfile
#from pyspark.sql.functions import col, unix_timestamp,to_date,avg,sum,min,max,count,month,current_date,year

spark = SparkSession.builder \
    .appName("GCS_to_BQ") \
    .getOrCreate()

# GCS path to input data (e.g., CSV)
gcs_input_path = "gs://sudip1507/titanic.csv"

# BigQuery target table
bq_table = "dataengineering-466011.titanic.titanic_data"

# Read CSV data from GCS
df = spark.read.option("header", "true").csv(gcs_input_path)

# Optional: data transformation (e.g., select, filter, cast)
#df_transformed = df.select("column1", "column2")

# Write to BigQuery
df.write \
    .format("bigquery") \
    .option("table", bq_table) \
    .option("temporaryGcsBucket", "sudip1507") \
    .mode("append") \
    .save()