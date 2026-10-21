# Import this existing repository before applying; do not let Terraform try to create it.
resource "github_repository" "this" {
  name                   = var.repository_name
  visibility             = "public"
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true
  allow_auto_merge       = false
}

# On a personal repository, the owner is the administrator; GitHub does not
# support organization teams/admin groups for personal repositories.
resource "github_branch_protection" "main" {
  repository_id       = github_repository.this.name
  pattern             = "main"
  enforce_admins      = false
  allows_deletions    = false
  allows_force_pushes = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
    restrict_dismissals             = true
    dismissal_restrictions          = ["/elouise-matthews"]
  }
}

# Explicitly listed collaborators are set to read-only. Add every non-owner
# collaborator here; Terraform cannot infer an unlisted collaborator's access.
resource "github_repository_collaborator" "read_only" {
  for_each   = var.read_only_collaborators
  repository = github_repository.this.name
  username   = each.value
  permission = "pull"
}
