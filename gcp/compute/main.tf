

resource "google_compute_instance" "node" {
  name         = var.instance_name
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "kube-install"
      }
    }
  }

  // Local SSD disk
  #  scratch_disk {
  #    interface = "NVME"
  #  }

  network_interface {
    network    = "kube-vpc"
    subnetwork = "test-subnetwork"

  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["cloud-platform"]
  }
}
