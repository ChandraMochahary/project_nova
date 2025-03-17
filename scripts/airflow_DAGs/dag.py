from airflow import DAG
from airflow.operators.dummy import DummyOperator
from airflow.providers.google.cloud.operators.dataflow import DataflowStartFlexTemplateOperator
# from airflow.operators.bash import BashOperator
# from airflow.operators.python import PythonOperator
from datetime import datetime
from airflow.models import Variable
from google.cloud import secretmanager
import os


PROJECT_ID = os.environ.get("PROJECT_ID_NAME")
REGION = os.environ.get("REGION",)
GCS_BUCKET_NAME = os.environ.get("GCS_BUCKET_NAME")
VPC_NAME = os.environ.get("VPC_NAME")
SUBNET_NAME = os.environ.get("SUBNET_NAME")
DATASET_NAME = os.environ.get("DATASET_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")
HOST_IP = os.environ.get("HOST_IP")

containerSpecGcsPath = "gs://dataflow-templates-us-central1/latest/flex/Jdbc_to_BigQuery_Flex"


def get_secret_data(project_id, secret_id, version_id):
    client = secretmanager.SecretManagerServiceClient()
    secret_detail = f"projects/{project_id}/secrets/{secret_id}/versions/{version_id}"
    response = client.access_secret_version(request={"name": secret_detail})
    data = response.payload.data.decode("UTF-8")
    return data

DB_USERNAME=get_secret_data(PROJECT_ID,'database_user',1)
DB_PASSWORD=get_secret_data(PROJECT_ID,'database_password',1)



with DAG(
    dag_id='load_onprem_bigquery_dag',
    start_date=datetime(2023, 1, 1),
    schedule_interval='0 0 * * *',
    catchup=False,
) as dag:

    start_task = DummyOperator(task_id='start')

    t1 = DataflowStartFlexTemplateOperator(
        task_id='load_onprem_bigquery_task',
        project_id=PROJECT_ID,  
        location=REGION,  
        body={
            "launchParameter": {
                "jobName": "load-onprem-bigquery-job",
                "containerSpecGcsPath": containerSpecGcsPath,
                "parameters": {
                    "driverJars" : f"gs://{GCS_BUCKET_NAME}/jars/postgresql-42.7.5.jar",
                    "driverClassName" : "org.postgresql.Driver",
                    "connectionURL" : f"jdbc:postgresql://{HOST_IP}:5432/{DATASET_NAME}",
                    "outputTable" : f"{PROJECT_ID}:{DATASET_NAME}.{TABLE_NAME}",
                    "bigQueryLoadingTemporaryDirectory":f"gs://{GCS_BUCKET_NAME}/temp_dataflow/",
                    "username" : DB_USERNAME,
                    "password" : DB_PASSWORD,
                    "query" : f"select * from {TABLE_NAME} WHERE TX_TS >= NOW() - INTERVAL '25 days';" 
                },
                "environment": {
                    "tempLocation":f"gs://{GCS_BUCKET_NAME}/temp_df",
                    "network": f"projects/{PROJECT_ID}/globals/networks/{VPC_NAME}",
                    "subnetwork": f"regions/{REGION}/subnetworks/{SUBNET_NAME}", 
                    "ipConfiguration" : "WORKER_IP_PRIVATE",
                    "numWorkers": 2,
                    "machineType": "n1-standard-4",
                    "serviceAccountEmail":f"composer-env-account@{PROJECT_ID}.iam.gserviceaccount.com",
                },
            },
        },
    )


    start_task >> t1