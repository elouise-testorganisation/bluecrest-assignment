# GitHub repository configuration

This Terraform configuration manages the existing `elouise-matthews/bluecrest-assignment` repository and protection for its `main` branch.

## Intended access model

- The desired release state is **public** so reviewers can view and clone the repository without invitations. Public means anyone on the internet can view it; it is not link-only access.
- **Do not run `apply-repo-config` until you are ready to publish.** Applying this configuration changes repository visibility to public if it is still private.
- Before publishing, inspect the full Git history, all branches and tags, Actions logs/artifacts, and files for credentials, tokens, personal data, or other sensitive information. Removing a secret from the latest version does not remove it from earlier commits; rotate any secret that was ever committed.
- This is a personal-account repository. The owner `elouise-matthews` is the administrator; GitHub organization teams/admin groups are not available here.
- No collaborator group is needed for public reviewers. Anonymous visitors have read-only access and can submit changes through pull requests from forks. They do not get direct write access.
- The `main` branch requires a pull request and a code-owner approval. The root `.github/CODEOWNERS` file names `@elouise-matthews` as code owner for every file.
- Stale approvals are dismissed when new commits are pushed; review conversations must be resolved before merge. Only the owner can dismiss reviews.
- Administrators can bypass branch protection because `enforce_admins = false`, preserving an owner recovery path.

GitHub allows other users to submit an “Approve” review, but a non-owner approval alone cannot satisfy the required code-owner review.

## Manual workflow

The `.github/workflows/apply-repo-config.yml` workflow is the only workflow for this Terraform configuration. It runs **only when manually dispatched**, accepts a `branch_name` input, checks formatting and validates the configuration, imports the current repository and existing `main` branch protection into the run's temporary state, then plans and applies the configuration.

Before using it:

1. Add a repository Actions secret named `REPO_CONFIG_TOKEN`. Use a fine-grained personal access token scoped only to this repository, with **Administration: read and write** permission. Keep the token private and rotate it if exposed.
2. If your repository uses GitHub Environments, protect the `repository-configuration` environment so only you can approve/start deployments.
3. Run **Actions → apply-repo-config → Run workflow**, and enter the branch containing the Terraform configuration you intend to apply. Only run a trusted branch you have reviewed.
4. Read the run logs and review the planned changes. If the repository is still private, the apply step will make it public.

The workflow uses temporary local state for each run: it imports the live repository and existing branch protection afresh, applies changes, and does not persist the state or store it as an artifact. This avoids committing state to the repository. Runs are serialized to avoid concurrent changes. The workflow must be run by an authorized user with permission to dispatch it.

## Terraform scope

The configuration manages the repository settings and `main` branch protection only. It does not manage collaborator permissions: public reviewers need no collaborator access. If you later add people who need direct write access, manage that separately and grant the minimum required permissions.

For local validation, use Terraform 1.5 or later. Do not commit `terraform.tfstate`, `.terraform/`, plan files, credentials, or local variable files.
