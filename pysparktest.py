import os
import pyspark
from pyspark.sql import SparkSession
import warnings


warnings.filterwarnings("ignore")
os.environ["JAVA_HOME"] = "C:\Program Files\Java\jdk-22"
# Set SPARK_HOME if not already set
os.environ["SPARK_HOME"] = "C:\\Users\\sudyr\\AppData\\Local\\Packages\\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\\LocalCache\\local-packages\\Python311\\site-packages\\pyspark\\bin" # Replace with your Spark installation path
os.environ["HADOOP_HOME"] = "C:/hadoop/bin" # Required for Windows
# Check Java installation
java_home = os.getenv("JAVA_HOME")
if java_home is None:
    print("JAVA_HOME environment variable is not set.")
else:
    print(f"JAVA_HOME is set to: {java_home}")
# Check Spark installation
spark_home = os.getenv("SPARK_HOME")
if spark_home is None:
    print("SPARK_HOME environment variable is not set.")
else:
    print(f"SPARK_HOME is set to: {spark_home}")
# Create SparkSession
try:
    print("SparkSession creation staring")
    spark = (
    SparkSession.builder#.appName("quickstart1")
    .getOrCreate()
    )
    print("SparkSession created successfully!")
except Exception as e:
    print(f"Error creating SparkSession: {e}")
# Create DataFrame
data = [
("James", "zen", "Smith", "1991-04-01", "M", 3000),
("Michael", "Rose", "zwee", "2000-05-19", "M", 4000),
("Robert", "", "Williams", "1978-09-05", "M", 4000),
("Maria", "Anne", "Jones", "1967-12-01", "F", 4000),
("Jen", "Mary", "Brown", "1980-02-17", "F", 400),
]
columns = ["firstname", "middlename", "lastname", "dob", "gender", "salary"]
df = spark.createDataFrame(data=data, schema=columns)
df.show(truncate=False)