output "pool_name" {
  value = google_iam_workload_identity_pool.my_github_pool.name
}

output "pool_provider_id" {
  value = google_iam_workload_identity_pool_provider.my_github_provider.id
}

output "sa_email" {
  value = google_service_account.my_service_account.email
}
