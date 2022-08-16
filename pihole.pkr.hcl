packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project" {
  type = string
  sensitive = true
}

variable "host_name" {
  type    = string
  default = "pihole"
}

variable "ipv4_address" {
  type    = string
  default = ""
}

variable "ipv6_address" {
  type    = string
  default = ""
}

variable "pi_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "pihole_web_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "user_name" {
  type    = string
  default = ""
}

variable "user_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "user_public_key" {
  type    = string
  default = ""
}

source "googlecompute" "pihole" {
  project_id = var.project
  source_image = "debian-9-stretch-v20200805"
  ssh_username = "packer"
  zone = "us-east1-c"
}

build {
  sources = ["source.googlecompute.pihole"]

  provisioner "shell" {
    inline = ["perl -pi -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen", "locale-gen de_DE.UTF-8", "update-locale de_DE.UTF-8"]
  }

  provisioner "shell" {
    inline = ["apt-get update", "apt-get upgrade -y", "touch /boot/ssh", "echo '${var.host_name}' | tee /etc/hostname", "mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig"]
  }

  provisioner "file" {
    destination = "/etc/ssh/sshd_config"
    source      = "sshd_config"
  }

  provisioner "shell" {
    inline = ["if [ ! -z '${var.pi_password}' ]; then", "  echo 'pi:${var.pi_password}' | chpasswd", "fi", "rm /etc/sudoers.d/010_pi-nopasswd", "echo 'pi ALL=(ALL) PASSWD: ALL' | tee /etc/sudoers.d/010_pi-passwd"]
  }

  provisioner "shell" {
    inline = ["if [ ! -z '${var.user_name}' ]; then", "  useradd -p $(openssl passwd -1 ${var.user_password}) -m ${var.user_name}", "  usermod -a -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi ${var.user_name}", "  mkdir -p /home/${var.user_name}/.ssh", "  echo '${var.user_public_key}' | tee /home/${var.user_name}/.ssh/authorized_keys", "  chown -R ${var.user_name}:${var.user_name} /home/${var.user_name}/.ssh", "  chmod 600 /home/${var.user_name}/.ssh/authorized_keys", "  echo 'AllowUsers ${var.user_name}' | tee -a /etc/ssh/sshd_config", "  echo '${var.user_name} ALL=(ALL) PASSWD: ALL' | tee /etc/sudoers.d/020_${var.user_name}-passwd", "fi", "mkdir -p /etc/pihole"]
  }

  provisioner "file" {
    destination = "/etc/pihole/setup.conf"
    source      = "setup.conf"
  }

  provisioner "shell" {
    inline = ["WEBPASSWORD=$(echo -n '${var.pihole_web_password}' | sha256sum | awk '{printf \"%s\",$1 }' | sha256sum | awk '{printf \"%s\",$1}')", "echo \"WEBPASSWORD=$${WEBPASSWORD}\" | tee -a /etc/pihole/setup.conf", "echo 'IPV4_ADDRESS=${var.ipv4_address}' | tee -a /etc/pihole/setup.conf", "echo 'IPV6_ADDRESS=${var.ipv6_address}' | tee -a /etc/pihole/setup.conf", "curl -L https://install.pi-hole.net | bash /dev/stdin --unattended"]
  }

}
