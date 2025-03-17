# Bigquery Dataset

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_name
  friendly_name               = "friendly_name_nova"
  description                 = "This is a test description"
  location                    = var.region

  labels = {
    job_type = "stream"
  }
}

resource "google_bigquery_table" "transactions" {
    dataset_id = google_bigquery_dataset.dataset.dataset_id
    table_id   = var.table_name
    deletion_protection=false

    labels = {
    job_type = "stream"
    }

  schema = <<EOF
[
    {
        "name": "TX_ID",
        "type": "STRING",
        "mode": "NULLABLE"
    },
    {
        "name": "TX_TS",
        "type": "TIMESTAMP",
        "mode": "NULLABLE"
    },
    {
        "name": "CUSTOMER_ID",
        "type": "STRING",
        "mode": "NULLABLE"
    },
    {
        "name": "TERMINAL_ID",
        "type": "STRING",
        "mode": "NULLABLE"
    },
    {
        "name": "TX_AMOUNT",
        "type": "NUMERIC",
        "mode": "NULLABLE"
    }
]
EOF

}