# Bluecrest time-series app

## Python application

- A small Streamlit app reads a CSV, cleans column names and parses dates and numeric values, then displays a selectable time-series line chart and data table.
- Missing or malformed cells are handled where possible so one bad value does not stop the whole dataset from rendering; unusable rows are excluded and missing observations remain gaps.
- Unit and app-level tests cover valid and malformed CSVs, missing files/headers, and rendering the chart and table.
- Run locally using the commands below; set `BLUECREST_DATA_FILE` to choose a CSV file (the container default is `/data/data.csv`).

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r src/app/requirements.txt
cd src
PYTHONPATH=app streamlit run app/app.py
```

Run tests with `cd src && PYTHONPATH=app python -m unittest discover -s test -v`.

## Kubernetes deployment

- Helm charts live under `deployment/helm`: `timeseries-application` deploys the app, and `cluster-infrastructure` creates cluster prerequisites including the production namespace and its resource quota.
- The app chart manages a Deployment, an internal `ClusterIP` Service, and a NetworkPolicy. The CSV is supplied as a ConfigMap and mounted read-only; the app has readiness/liveness probes and CPU/memory requests and limits.
- Pod/container hardening includes a non-root user, the runtime-default seccomp profile, a read-only root filesystem, disabled privilege escalation, and dropped Linux capabilities. Images are pulled using a Kubernetes image-pull secret.
- Public Ingress is disabled by default. The NetworkPolicy restricts inbound traffic unless optional ingress is enabled through the configured ingress controller.
- `values-dev.yaml` uses one replica and lower resource requests/limits for development. `values-prod.yaml` uses two replicas and higher resource requests/limits. Both keep Ingress disabled and enable the NetworkPolicy.
- This is configuration, not a fully secured production environment: there is no managed environment here in which to configure and verify perimeter/node/cloud firewalls, public routing, TLS, and cluster-level controls. NetworkPolicy enforcement also depends on the cluster CNI; it does not replace firewall rules. Those controls must be designed and tested in the actual hosting environment before exposing the app.
- The deployment workflows expect a self-hosted GitHub Actions runner labelled `linux` and `minikube`, access to the target cluster, and the `GHCR_PULL_USERNAME` / `GHCR_PULL_TOKEN` secrets.

## GitHub Actions workflows

- **Tests** — `.github/workflows/tests.yml`. Runs the Python test suite on Python 3.12 and publishes the `testsPassed` check. Triggered manually with a ref, called by other workflows, or by adding the `runTests` label to a PR.
- **Build image** — `.github/workflows/build.yml`. Builds and publishes the multi-architecture container image and packages the app Helm chart to GHCR. Main builds publish versioned production tags; other refs use a short-SHA development tag. Publishes `imageBuildPassed` and `stackBuildPassed`. Triggered manually with a ref, called by other workflows, or by adding the `buildImage` label to a PR.
- **Development deploy** — `.github/workflows/dev-deploy.yml`. Runs tests and build first, deploys a non-main ref to a unique temporary namespace, checks rollout and HTTP health, then requests namespace cleanup after 10 minutes. Triggered manually with a non-main ref or by adding `deployDev` to a PR targeting a non-main branch.
- **Production deploy** — `.github/workflows/prod-deploy.yml`. Runs tests and build before deploying to `bluecrest-prod`, then checks rollout and HTTP health. Triggered by a push to `main` or manually, with manual deployments restricted to `main`.
- **Bootstrap Minikube infrastructure** — `.github/workflows/apply-infrastructure.yml`. Manually installs/updates the cluster-infrastructure chart and configures the production GHCR pull secret. Requires the self-hosted Minikube runner and the GHCR pull secrets.

## Pull-request checks and future work

- The Terraform example under `future-work/configuration/terraform/` shows how repository settings and `main` branch protection could be managed from a separate repository with appropriate permissions. It is an example only and has not been applied to the live repository.
- The example config currently requires the `testsPassed`, `imageBuildPassed`, and `stackBuildPassed` status checks on `main`. Administrators can bypass these rules because `enforce_admins = false`; conversation resolution is required, and force pushes and branch deletion are blocked.
- The current Terraform example lists **three** named required checks, while the intended/manual repository setup has been described as requiring **four** check runs. Identify and add the fourth check context before relying on or applying this Terraform configuration.
- Repository and branch permissions are currently configured manually. Review the Terraform owner/repository settings and permissions before any future plan/apply; import the existing repository into Terraform state first rather than attempting to create it.
