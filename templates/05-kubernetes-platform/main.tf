variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}
variable "kube_context" { type = string }
variable "name" {
  type    = string
  default = "iac-platform"
}
variable "image" {
  type = string
  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.image))
    error_message = "Use digest sha256 inmutable."
  }
}
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}
resource "kubernetes_resource_quota_v1" "this" {
  metadata {
    name      = "budget"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    hard = { "requests.cpu" = "1", "requests.memory" = "1Gi", "limits.cpu" = "2", "limits.memory" = "2Gi", pods = "6" }
  }
}
resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = "app"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = { app = var.name }
  }
  spec {
    replicas = 2
    selector { match_labels = { app = var.name } }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }
    template {
      metadata { labels = { app = var.name } }
      spec {
        automount_service_account_token = false
        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001
          fs_group        = 10001
          seccomp_profile { type = "RuntimeDefault" }
        }
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "ScheduleAnyway"
          label_selector { match_labels = { app = var.name } }
        }
        container {
          name  = "app"
          image = var.image
          port { container_port = 8080 }
          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities { drop = ["ALL"] }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }
          liveness_probe {
            tcp_socket { port = 8080 }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }
        volume {
          name = "tmp"
          empty_dir { size_limit = "64Mi" }
        }
      }
    }
  }
  depends_on = [kubernetes_resource_quota_v1.this]
}
resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "app"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    selector = { app = var.name }
    type     = "ClusterIP"
    port {
      port        = 8080
      target_port = 8080
    }
  }
}
resource "kubernetes_pod_disruption_budget_v1" "app" {
  metadata {
    name      = "app"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    min_available = "1"
    selector { match_labels = { app = var.name } }
  }
}
resource "kubernetes_network_policy_v1" "app" {
  metadata {
    name      = "app-isolation"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    pod_selector { match_labels = { app = var.name } }
    policy_types = ["Ingress", "Egress"]
    ingress {
      from {
        namespace_selector { match_labels = { "kubernetes.io/metadata.name" = var.name } }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
    # Sin reglas de egress: aplicación demo no necesita DNS ni servicios externos.
  }
}
output "namespace" { value = kubernetes_namespace_v1.this.metadata[0].name }
output "service_dns" { value = "app.${var.name}.svc.cluster.local:8080" }
