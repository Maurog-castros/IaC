mock_provider "google" {}
variables {
  project_id     = "iac-demo-project"
  image          = "example.com/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  invoker_member = "serviceAccount:caller@iac-demo-project.iam.gserviceaccount.com"
}
run "bounded_scaling" {
  command = plan
  assert {
    condition     = google_cloud_run_v2_service.this.template[0].scaling[0].max_instance_count == 3 && google_cloud_run_v2_service.this.template[0].scaling[0].min_instance_count == 0
    error_message = "Demo debe escalar entre cero y tres instancias."
  }
}
run "reject_mutable_image" {
  command = plan
  variables { image = "example.com/app:latest" }
  expect_failures = [var.image]
}
run "reject_public_invoker" {
  command = plan
  variables { invoker_member = "allUsers" }
  expect_failures = [var.invoker_member]
}
