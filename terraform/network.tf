resource "google_compute_address" "ip_address" {
  name = "pihole-address"
}

output "ip_address" {
  value       = google_compute_address.ip_address.address
  description = "static ip for the pihole"
}

resource "local_file" "ip_address_output" {
    content  = google_compute_address.ip_address.address
    filename = "${path.module}/ip_address.txt"
}
