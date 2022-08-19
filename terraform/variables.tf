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

variable "image" {
  type = string
  default = ""
}

variable "ipv4_address" {
  type = string
  default = ""
}
