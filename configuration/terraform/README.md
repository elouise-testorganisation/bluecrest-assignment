# GitHub repository configuration

This Terraform configuration manages the existing `elouise-matthews/bluecrest-assignment` repository and its `main` branch protection.

## Intended access model

- The repository is owned by the personal account `elouise-matthews`, which is its administrator. GitHub teams/admin groups are not available for personal repositories.
- Other collaborators should have `pull` (read-only) permission. Add every non-owner collaborator to `read_only_collaborators` in `terraform.tfvars`. Contributors can still propose changes through pull requests, including from forks.
- `main` requires pull requests and a code-owner approval. The root `.github/CODEOWNERS` file names `@elouise-matthews` as the code owner.
- Stale approvals are dismissed when new commits are pushed. Only the owner can dismiss reviews.
- Administrators are not subject to the branch protection rules, so the owner retains an administrative recovery/bypass path.

GitHub allows other users to submit an “Approve” review, but a non-owner approval alone cannot satisfy the required code-owner review.

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
# Edit terraform.tfvars and list every non-owner collaborator.
terraform plan
```

Review the plan carefully before running `terraform apply`. The initial plan should be reviewed for any unrelated settings Terraform proposes to change. Keep `terraform.tfstate`, `.terraform/`, and any real `terraform.tfvars` file out of version control.

## Scope and limitations

The collaborator resource sets the permission of each username listed in `read_only_collaborators` to read-only; it does not automatically discover or remove unlisted collaborators. Inventory current collaborators and list all of them before applying if you want to enforce the read-only policy consistently.

Because this is a personal repository, Terraform cannot create a separate one-person GitHub admin team. If you later move the repository into an organization, an organization team can be created and managed separately.
