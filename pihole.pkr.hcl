packer {
  required_plugins {
    googlecompute = {
      version = "= 1.0.14"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "pkr_access_token" {
  type      = string
  sensitive = true
}

variable "project" {
  type = string
}

variable "host_name" {
  type    = string
  default = "pihole"
}

variable "ipv4_address" {
  type = string
}

variable "pihole_web_password" {
  type      = string
  sensitive = true
}

variable "user_name" {
  type      = string
  sensitive = true
}

variable "user_password" {
  type      = string
  sensitive = true
}

variable "image_version" {
  type = string
}

source "googlecompute" "pihole" {
  project_id   = var.project
  source_image = "debian-11-bullseye-v20220719"
  ssh_username = var.user_name
  ssh_password = var.user_password
  zone         = "us-east1-c"
  machine_type = "f1-micro"
  disk_size    = 30
  image_name   = "pihole-${var.image_version}"
  access_token = var.pkr_access_token
}

build {
  sources = ["source.googlecompute.pihole"]

  provisioner "shell" {
    inline = ["echo '${var.ipv4_address}'"]
  }

  provisioner "shell" {
    inline          = ["apt-get update", "apt-get upgrade -y", "touch /boot/ssh", "echo '${var.host_name}' | tee /etc/hostname", "mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }

  provisioner "file" {
    destination = "/tmp/sshd_config"
    source      = "files/tmp/sshd_config"
  }

  provisioner "shell" {
    inline          = ["mv /tmp/sshd_config /etc/ssh/sshd_config"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }

  provisioner "file" {
    destination = "/tmp/setupVars.conf"
    source      = "files/tmp/setupVars.conf"
  }

  provisioner "shell" {
    inline          = ["mkdir /etc/pihole", "mv /tmp/setupVars.conf /etc/pihole/setupVars.conf"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }

  provisioner "shell" {
    inline          = ["WEBPASSWORD=$(echo -n '${var.pihole_web_password}' | sha256sum | awk '{printf \"%s\",$1 }' | sha256sum | awk '{printf \"%s\",$1}')", "echo \"WEBPASSWORD=$${WEBPASSWORD}\" | tee -a /etc/pihole/setupVars.conf", "echo 'IPV4_ADDRESS=${var.ipv4_address}' | tee -a /etc/pihole/setupVars.conf", "curl -L https://install.pi-hole.net | bash /dev/stdin --unattended"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }

  provisioner "shell" {
    inline = ["hostnamectl set-hostname pihole"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }

  provisioner "file" {
    destination = "/tmp/vpnOptions.conf"
    source      = "files/tmp/vpnOptions.conf"
  }

  provisioner "shell" {
    inline = ["mkdir /usr/local/src/pivpn", "curl -L https://install.pivpn.io > install.sh", "chmod +x install.sh", "./install.sh --unattended /tmp/vpnOptions.conf"]
    execute_command = "echo '${var.user_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
  }
}
