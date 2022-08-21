resource "google_compute_instance" "pihole" {
  name         = "pihole"
  machine_type = "f1-micro"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.ipv4_address
    }
  }
}
