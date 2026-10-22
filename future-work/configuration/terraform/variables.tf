variable "github_owner" {
  description = "GitHub organization or user that owns the repository."
  type        = string
  default     = "elouise-testorganisation"
}

variable "repository_name" {
  description = "Existing repository to manage."
  type        = string
  default     = "bluecrest-assignment"
}
