resource "google_compute_instance" "pihole" {
  name         = "pihole"
  machine_type = "f2-micro"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    access_config {
      nat_ip = var.ipv4_address
    }
  }
}
