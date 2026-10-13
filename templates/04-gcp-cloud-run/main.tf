variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "us-central1"
}
variable "name" {
  type    = string
  default = "iac-run"
}
variable "image" {
  type = string
  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.image))
    error_message = "Use imagen inmutable con digest sha256 de 64 caracteres."
  }
}
variable "invoker_member" {
  type = string
  validation {
    condition     = can(regex("^serviceAccount:[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", var.invoker_member))
    error_message = "Invoker debe ser una service account, nunca allUsers."
  }
}
resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}
resource "google_service_account" "runtime" {
  account_id   = "${var.name}-runtime"
  display_name = "Cloud Run runtime without project roles"
}
resource "google_cloud_run_v2_service" "this" {
  name                = var.name
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  labels              = { managed-by = "terraform", environment = "demo" }
  template {
    service_account = google_service_account.runtime.email
    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
    timeout                          = "30s"
    max_instance_request_concurrency = 20
    containers {
      image = var.image
      ports { container_port = 8080 }
      resources {
        limits   = { cpu = "1", memory = "256Mi" }
        cpu_idle = true
      }
      startup_probe {
        initial_delay_seconds = 0
        period_seconds        = 5
        failure_threshold     = 10
        tcp_socket { port = 8080 }
      }
    }
  }
  depends_on = [google_project_service.run]
}
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = var.invoker_member
}
output "service_url" { value = google_cloud_run_v2_service.this.uri }
output "runtime_identity" { value = google_service_account.runtime.email }
