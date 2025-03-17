
/////////////////////// On Prem Database

resource "google_service_account" "compute_on_prem_db_sa" {
  account_id   = "compute-on-prem-db-sa"
  display_name = "Custom SA for My Compute VM Instance for On-Prem DB - PSQL"
}

resource "google_project_iam_member" "iam_compute_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.compute_on_prem_db_sa.email}"
  depends_on = [ google_service_account.compute_on_prem_db_sa ]
}


resource "google_project_iam_member" "iam_compute_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.compute_on_prem_db_sa.email}"
  depends_on = [ google_service_account.compute_on_prem_db_sa ]
}

resource "google_compute_instance" "compute_on_prem_db" {
  name         = "onprem-psql-db"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

    shielded_instance_config {
        enable_secure_boot = true
    }

  tags = ["dev", "psql"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 50
      labels = {
        my_label = "value"
      }
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = var.network_name
    subnetwork = var.subnet_name

    # access_config {
    #   // Ephemeral public IP
    # }
  }

  metadata = {
    desc = "on_prem_psql_db"
  }

  metadata_startup_script = templatefile("./modules/compute_instance/psql_start_up.sh",{ 
    db_username = var.db_username,
    table_name = var.table_name,
    database_name = var.dataset_name,
    bucket_name = var.gcs_bucket,
    db_password = var.db_password
  })

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.compute_on_prem_db_sa.email
    scopes = ["cloud-platform"]
  }
}


output "host_ip" {
  value = google_compute_instance.compute_on_prem_db.network_interface.0.network_ip
  description = "The Private IP address of the instance."
}


///////////////////////////////  SFTP Server

# resource "google_service_account" "compute_sftp_sa" {
#   account_id   = "compute-sftp-sa"
#   display_name = "Custom SA for My Compute VM Instance for SFTP Server"
# }

# resource "google_compute_instance" "compute_sftp" {
#     name         = "sftp-server"
#     machine_type = "n2-standard-2"
#     zone         = "us-central1-a"

#     shielded_instance_config {
#         enable_secure_boot = true
#     }
#     tags = ["dev", "sftp"]

#     boot_disk {
#     initialize_params {
#         image = "debian-cloud/debian-11"
#         size = 20
#         labels = {
#         my_label = "disk_label"
#         }
#     }
#     }

#   // Local SSD disk
#   scratch_disk {
#     interface = "NVME"
#   }

#   network_interface {
#     network = var.network_name
#     subnetwork = var.subnet_name

#     # access_config {
#     #   // Ephemeral public IP
#     # }
#   }

#   metadata = {
#     desc = "sftp_server"
#   }

#   metadata_startup_script = <<-EOF
#     #!/bin/bash

#     # Update package lists
#     sudo apt update -y

#     # Install PostgreSQL
#     sudo apt install postgresql-contrib -y

#     "echo hi > /sftp.txt"
# EOF

#   service_account {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     email  = google_service_account.compute_on_prem_db_sa.email
#     scopes = ["cloud-platform"]
#   }
# }