# GitHub repository configuration

This Terraform configuration manages the existing `elouise-matthews/bluecrest-assignment` repository and its `main` branch protection.

## Intended access model

- The desired release state is **public** so reviewers can view the code without being invited. Public means anyone on the internet can view and clone the repository; it is not private link-only access.
- The Terraform configuration declares `visibility = "public"`. **Do not run `terraform apply` until you are ready to make the repository public.** Terraform will plan a visibility change if the live repository is still private.
- Before publishing, inspect the complete repository history, branches, tags, Actions logs/artifacts, and files for credentials, tokens, personal data, and anything else that must not be public. Removing a secret from the latest version does not remove it from Git history; rotate any secret that was ever committed.
- The repository is owned by the personal account `elouise-matthews`, which is its administrator. GitHub teams/admin groups are not available for personal repositories.
- Anonymous visitors receive public read access, not write access. Reviewers can submit changes via pull requests from forks without being added as collaborators.
- The `main` branch requires pull requests and a code-owner approval. The root `.github/CODEOWNERS` file names `@elouise-matthews` as the code owner for every file.
- Stale approvals are dismissed when new commits are pushed; review conversations must be resolved before merge. Only the owner can dismiss reviews.
- Administrators can bypass branch protection because `enforce_admins = false`, preserving an owner recovery path.

GitHub allows other users to submit an “Approve” review, but a non-owner approval alone cannot satisfy the required code-owner review. Code-owner review enforcement requires GitHub to recognize the owner as a code owner with write access.

## Prerequisites

- Terraform 1.5 or later.
- A GitHub token available in the `GITHUB_TOKEN` environment variable with permission to administer this repository and manage branch protection/collaborators. Do not commit the token or Terraform state.
- Repository and branch-protection permissions may depend on the GitHub plan and repository settings.

## First-time setup

Run these commands from this directory. Import the existing resources before planning; otherwise Terraform may try to create a repository that already exists.

```sh
terraform init
terraform import github_repository.this elouise-matthews/bluecrest-assignment
terraform import github_branch_protection.main bluecrest-assignment:main
cp terraform.tfvars.example terraform.tfvars
# Add only known collaborators who should have read-only access.
terraform plan
```

Review the plan carefully before running `terraform apply`. If the live repository is still private, the plan will make it public. Confirm that you are ready to publish before applying. Review any unrelated settings Terraform proposes to change. Keep `terraform.tfstate`, `.terraform/`, plan files, and any real `terraform.tfvars` out of version control. The local state file may contain sensitive repository metadata; store it securely and back it up safely.

## Scope and limitations

The collaborator resource sets the permission of each username listed in `read_only_collaborators` to read-only; it does not automatically discover or remove unlisted collaborators. Public reviewers do not need to be listed as collaborators. Inventory existing collaborators and list them if you want Terraform to manage their access explicitly.

Because this is a personal repository, Terraform cannot create a separate one-person GitHub admin team. If you later move the repository into an organization, an organization team can be created and managed separately.
