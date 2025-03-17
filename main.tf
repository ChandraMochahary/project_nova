
# Enable APIs

resource "google_project_service" "enabled_services" {
  for_each = toset(var.enabled_apis)
  project  = var.project_id
  service  = each.value
  #   disable_dependent_services = true
  disable_on_destroy = false #optional, set to false if you want the API to remain enabled when terraform destroy is run.
}

# Wait for API to enable

resource "time_sleep" "wait_for_api_to_enable" {
  create_duration = "120s" # Adjust duration as needed
}

# VPC setup 

module "vpc_resources" {
  source = "./modules/vpc" 
  project_id = var.project_id
  network_name = var.network_name
  region = var.region
  subnet_name = var.subnet_name
  depends_on = [ time_sleep.wait_for_api_to_enable ]
}

module "secret_manager_resources" {
  source = "./modules/secret_manager" 
  region = var.region
  depends_on = [ time_sleep.wait_for_api_to_enable ]
}


module "compute_resources" {
  source = "./modules/compute_instance"
  project_id = var.project_id
  network_name = var.network_name
  region = var.region
  gcs_bucket = var.gcs_bucket
  db_password = module.secret_manager_resources.db_password_output
  depends_on = [ module.vpc_resources ]
}


module "bigquery_resources" {
  source = "./modules/bigquery" 
  depends_on = [ time_sleep.wait_for_api_to_enable ]
  dataset_name = var.dataset_name
}


module "composer_resources" {
  source = "./modules/composer" 
  gcs_bucket = var.gcs_bucket
  project_id = var.project_id
  region = var.region
  host_ip = module.compute_resources.host_ip
  depends_on = [ module.vpc_resources ]
}


