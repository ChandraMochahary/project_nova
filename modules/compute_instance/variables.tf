variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcs_bucket" {
  type        = string
  description = "GCS bucket for Whole Deployment"
}

variable "region" {
  type        = string
  default = "us-central1"
  description = "Deployment region"
}

variable "network_name" {
  type        = string
  default     = "nova-vpc" 
}


variable "subnet_name" { 
  default = "nova-subnet"
  type    = string
}

variable "dataset_name" { 
  default = "nova_corp"
  type    = string
}

variable "table_name" { 
  default = "transactions"
  type    = string
}


variable "db_username" { 
  default = "db_user"
  type    = string
}

variable "db_password" { 
  default = "db_password"
  type    = string
  sensitive = true
}

