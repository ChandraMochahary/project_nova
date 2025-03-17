
// Service Account for Composer Environment

resource "google_service_account" "composer-env-account" {
  account_id   = "composer-env-account"
  display_name = "Service Account for Composer Environment"
}

resource "google_project_iam_member" "composer-worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer-env-account.email}"
  depends_on = [ google_service_account.composer-env-account ]
}

resource "google_project_iam_member" "composer-dataflowdeveloper" {
  project = var.project_id
  role    = "roles/dataflow.serviceAgent"
  member  = "serviceAccount:${google_service_account.composer-env-account.email}"
  depends_on = [ google_service_account.composer-env-account ]
}

resource "google_project_iam_member" "composer-secret-accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.composer-env-account.email}"
  depends_on = [ google_service_account.composer-env-account ]
}

resource "google_project_iam_member" "composer-bigquery-admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.composer-env-account.email}"
  depends_on = [ google_service_account.composer-env-account ]
}

resource "google_project_iam_member" "composer-dataflow-worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.composer-env-account.email}"
  depends_on = [ google_service_account.composer-env-account ]
}

// Composer Environment

resource "google_composer_environment" "composer_3" {
  name   = "composer-3"
  region = var.region
  config {

    software_config {
      image_version = "composer-3-airflow-2"
      env_variables = {
        PROJECT_ID_NAME = var.project_id
        REGION = var.region
        GCS_BUCKET_NAME = var.gcs_bucket
        VPC_NAME = var.network_name
        SUBNET_NAME = var.subnet_name
        DATASET_NAME = var.dataset_name
        TABLE_NAME = var.table_name
        HOST_IP = var.host_ip
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"


    node_config {
      service_account = google_service_account.composer-env-account.name
    }
  }

  depends_on = [ google_project_iam_member.composer-worker  ]
}

# Upload your DAG files to the DAGs bucket.

resource "google_storage_bucket_object" "dag_file1" {
  name   = "dags/dag.py" # name of dag file in bucket
  bucket = element(split("/", replace(google_composer_environment.composer_3.config[0].dag_gcs_prefix, "gs://", "")), 0)
  source = "./scripts/airflow_DAGs/dag.py" #local path to dag file
}

resource "google_storage_bucket_object" "load_jar_file" {
  name   = "jars/postgresql-42.7.5.jar" # The name of the object in the bucket
  bucket = var.gcs_bucket
  source = "./modules/composer/postgresql-42.7.5.jar" # Path to your local file
}


