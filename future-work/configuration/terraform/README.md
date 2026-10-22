# GitHub repository configuration

- These Terraform files are an example of how this repository's GitHub settings and `main` branch protection could be configured.
- The configuration could be maintained in a separate repository and applied with the appropriate permissions.
- This is an example only; for now the repository and it's branch permissions have been configured manually.
- the general setup is that only the admin can merge branches, and the admin is allowed to bypass the rules for pr merge. 
- there is no approval requirement on PRs, but the admins's write permission functions as a de-facto approval gate. 
- 4 checkruns must succeedon the PR to be merged - although an admin can bypass this. 
