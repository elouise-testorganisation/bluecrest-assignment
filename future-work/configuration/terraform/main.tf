resource "github_repository" "this" {
  name                   = var.repository_name
  visibility             = "public"
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true
  vulnerability_alerts   = true
}

# Administrators can bypass these rules; non-admins must satisfy required checks.
resource "github_branch_protection" "main" {
  repository_id                   = github_repository.this.name
  pattern                         = "main"
  enforce_admins                  = false
  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true

  required_status_checks {
    strict   = false
    contexts = [
      "testsPassed",
      "imageBuildPassed",
      "stackBuildPassed",
    ]
  }
}
