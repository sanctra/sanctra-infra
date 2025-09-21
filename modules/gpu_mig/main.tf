terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

# Instance template (GPU)
resource "google_compute_instance_template" "tmpl" {
  name_prefix  = "${var.name}-it-"
  machine_type = var.machine_type
  region       = var.region

  disk {
    auto_delete  = true
    boot         = true
    source_image = var.source_image
    disk_size_gb = var.boot_disk_gb
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {}
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = true
  }

  guest_accelerator {
    type  = var.accelerator_type
    count = var.accelerator_count
  }

metadata = {
    startup-script = var.startup_script != null ? var.startup_script : <<-EOT
      #!/usr/bin/env bash
      set -euo pipefail
      
      # Install NVIDIA drivers
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      apt-get install -y apt-transport-https ca-certificates
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
      apt-get update
      apt-get install -y google-guest-agent
      apt-get install -y 'linux-headers-$(uname -r)'
      
      # For L4 GPUs on Ubuntu 22.04
      apt-get install -y nvidia-driver-535-server
      
      # Install Docker
      apt-get install -y docker.io
      systemctl enable --now docker

      # Install NVIDIA container toolkit
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
      apt-get update
      apt-get install -y nvidia-container-toolkit
      nvidia-ctk runtime configure --runtime=docker
      systemctl restart docker
      
      # Pull and run service container with GPU access
      docker pull ${var.docker_image}
      docker rm -f ${var.name} || true
      docker run --restart=always -d --gpus all --name ${var.name} -p ${var.port}:${var.port} ${var.docker_image}
    EOT
  }

  tags = var.tags
  labels = var.labels
}

# Regional MIG
resource "google_compute_region_instance_group_manager" "mig" {
  name               = "${var.name}-mig"
  base_instance_name = var.name
  region             = var.region
  target_size        = var.size

  version {
    instance_template = google_compute_instance_template.tmpl.self_link
    name              = "primary"
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_percent     = 50
    max_unavailable_percent = 0
  }

  named_port {
    name = "http"
    port = var.port
  }
}
