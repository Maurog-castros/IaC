mock_provider "kubernetes" {}
variables {
  kube_context = "kind-iac"
  image        = "example.com/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}
run "workload_guardrails" {
  command = plan
  assert {
    condition     = tonumber(kubernetes_deployment_v1.app.spec[0].replicas) == 2 && !kubernetes_deployment_v1.app.spec[0].template[0].spec[0].automount_service_account_token
    error_message = "Dos réplicas y ningún token automático."
  }
  assert {
    condition     = kubernetes_deployment_v1.app.spec[0].template[0].spec[0].container[0].security_context[0].read_only_root_filesystem && !kubernetes_deployment_v1.app.spec[0].template[0].spec[0].container[0].security_context[0].allow_privilege_escalation
    error_message = "Filesystem inmutable y sin escalación."
  }
  assert {
    condition     = length(kubernetes_network_policy_v1.app.spec[0].egress) == 0
    error_message = "Demo debe negar egress."
  }
}
