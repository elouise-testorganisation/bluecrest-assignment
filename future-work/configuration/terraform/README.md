# GitHub repository configuration

This Terraform configuration manages the existing `elouise-matthews/bluecrest-assignment` repository and protection for its `main` branch.

## Intended access model

- The desired release state is **public** so reviewers can view and clone the repository without invitations. Public means anyone on the internet can view it; it is not link-only access.
- **Do not apply this configuration until you are ready to publish.** Applying it changes repository visibility to public if the repository is still private.
- Before publishing, inspect the full Git history, all branches and tags, Actions logs/artifacts, and files for credentials, tokens, personal data, or other sensitive information. Removing a secret from the latest version does not remove it from earlier commits; rotate any secret that was ever committed.
- This is a personal-account repository. The owner `elouise-matthews` is the administrator; GitHub organization teams/admin groups are not available here.
- Public reviewers need no collaborator access. They can view the public repository and submit changes through pull requests from forks; they do not get direct write access.
- The root `.github/CODEOWNERS` file names `@elouise-matthews` as code owner for every file.
- `main` is intended to require a pull request and code-owner approval. Stale approvals should be dismissed when new commits are pushed, review conversations should be resolved, and only the owner should be able to dismiss reviews.
- Administrators can bypass branch protection because `enforce_admins = false`, preserving an owner recovery path.

GitHub allows other users to submit an “Approve” review, but a non-owner approval alone cannot satisfy the required code-owner review.

## Applying manually

There is no GitHub Actions apply workflow in this repository. Review the Terraform configuration and use a trusted local environment with Terraform 1.5 or later and a fine-grained GitHub token scoped to `bluecrest-assignment` with **Administration: read and write** permission. Keep credentials out of source control. Import the existing repository and any existing `main` branch protection into Terraform state before planning, so Terraform manages the existing repository instead of trying to create it.

Review the complete plan before applying. If the repository is still private, the desired `visibility = "public"` setting will make it public. Audit the target repository's full history, branches, tags, Actions logs/artifacts, and files for secrets and sensitive data first.

## Terraform scope

The configuration manages repository settings and `main` branch protection only. It does not manage collaborator permissions because public reviewers do not need collaborator access. If you later grant anyone direct write access, manage that separately and grant the minimum required permission.

Do not commit Terraform state, `.terraform/`, plan files, credentials, or local variable files.
