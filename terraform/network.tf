resource "google_compute_address" "ip_address" {
  name = "pihole-address"
}

output "ip_address" {
  value       = google_compute_address.ip_address
  description = "static ip for the pihole"
}
