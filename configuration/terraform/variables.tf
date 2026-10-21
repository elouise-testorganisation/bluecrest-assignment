variable "github_owner" {
  description = "GitHub account that owns the repository."
  type        = string
  default     = "elouise-matthews"
}

variable "repository_name" {
  description = "Existing repository to manage."
  type        = string
  default     = "bluecrest-assignment"
}

variable "read_only_collaborators" {
  description = "GitHub usernames who should have read-only (pull) access. List every non-owner collaborator to manage."
  type        = set(string)
  default     = []
}
