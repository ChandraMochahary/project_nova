terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.25.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.7.1"
    }
  }

  backend "gcs" {
    bucket = "<YOUR_BUCKET_NAME>" # Name of the GCS BucKET which is created manually
    prefix = "terraform/state" # Optional: a prefix to organize state files within the bucket
  }

    required_version = ">= 1.11.1"
}

provider "google" {
    # Configuration options
    project     = var.project_id
    region      = var.region
}

provider "google-beta" {
    project     = var.project_id
    region      = var.region
}

provider "random" {
  # Configuration options
}