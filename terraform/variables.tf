variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "credentials" {
  type      = string
  sensitive = true
}
