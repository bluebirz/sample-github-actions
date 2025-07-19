resource "google_iam_workload_identity_pool" "my_github_pool" {
  provider = google-beta

  workload_identity_pool_id = var.wlid_pool_id
  display_name              = var.wlid_pool_display_name
  description               = "Identity pool operates in FEDERATION_ONLY mode for testing purposes"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "my_github_provider" {
  provider = google-beta

  workload_identity_pool_id          = google_iam_workload_identity_pool.my_github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wlid_pool_provider_id
  display_name                       = var.wlid_pool_provider_display_name
  description                        = "Provider for GitHub Actions to access Google Cloud resources"
  attribute_condition                = "assertion.repository_owner == '${var.wlid_pool_provider_repo_owner}'"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "my_service_account" {
  account_id   = var.wlid_sa
  display_name = var.wlid_sa_name
  description  = "Service account for GitHub Actions to access Google Cloud resources"
}

resource "google_service_account_iam_binding" "github_actions_sa_member" {
  service_account_id = google_service_account.my_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.my_github_pool.name}/attribute.repository_owner/${var.wlid_pool_provider_repo_owner}"]
}

resource "google_project_iam_member" "github_actions_sa_iam_roles" {
  for_each = toset([
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.admin",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.my_service_account.email}"
}
