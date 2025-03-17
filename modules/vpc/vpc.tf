resource "google_compute_network" "vpc_network" {
    name    = var.network_name
    project = var.project_id
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = var.subnet_name
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  project       = var.project_id
  network       = google_compute_network.vpc_network.name
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  priority      = 1000
  depends_on = [ google_compute_network.vpc_network ]
}

resource "google_compute_firewall" "allow_psql" {
  name    = "allow-psql"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 1000
  depends_on = [ google_compute_network.vpc_network ]
}

// This creates a router & NAT gateway for the private IP to access internet
module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"
  name    = "colab-router"
  project = var.project_id
  network = var.network_name
  region  = var.region
  nats = [{
    name                               = "colab-nat-gateway"
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      {
        name                     = var.subnet_name
        source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE"]
      }
    ]
  }]
  depends_on = [
    google_compute_subnetwork.vpc_subnetwork
  ]
}
