resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "test-subnetwork"
#  project       = "central-age-457904-v7"
  project       = var.project-id
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.kube-vpc.id
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
  depends_on = [google_compute_network.kube-vpc]
}
resource "google_compute_network" "kube-vpc" {
  project                 = var.project-id
#  project                 = "central-age-457904-v7"
  name                    = "kube-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}