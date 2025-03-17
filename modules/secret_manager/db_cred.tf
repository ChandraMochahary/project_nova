
// Generate Random string for password

resource "random_string" "db_password" {
  length  = 16
  upper   = true
  lower   = true
  numeric = true
  special = false #set to false, if you only want alphanumeric.
}


resource "google_secret_manager_secret" "database_password_secret" {
  secret_id = "database_password"
    replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "database_password_secret_version" {
  secret = google_secret_manager_secret.database_password_secret.id
  secret_data = random_string.db_password.result
}



resource "google_secret_manager_secret" "database_user_secret" {
  secret_id = "database_user"
    replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "database_user_secret_version" {
  secret = google_secret_manager_secret.database_user_secret.id
  secret_data = "db_user"
}
