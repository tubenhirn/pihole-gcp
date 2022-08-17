terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.32.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.32.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  credentials = var.credentials
}

provider "google-beta" {
  project = var.project
  region  = var.region
  credentials = var.credentials
}
