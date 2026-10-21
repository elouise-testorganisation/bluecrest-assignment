# Bluecrest time-series app

A minimal Streamlit application that cleans a CSV and plots numeric time series against a date column. Isolated missing or malformed cells do not prevent plotting.

## Local development

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r src/app/requirements.txt
cd src
PYTHONPATH=app streamlit run app/app.py
```

Set `BLUECREST_DATA_FILE` to select a local CSV; the container defaults to `/data/data.csv`.

Run tests with `cd src && PYTHONPATH=app python -m unittest discover -s test -v`.

## Container

```bash
docker build -t bluecrest:dev ./src
docker run --rm -p 8501:8501 -v "$PWD/src/data/data.csv:/data/data.csv:ro" bluecrest:dev
```

## Kubernetes / Helm

All charts are consolidated under `deployment/helm`: the app chart is `deployment/helm/timeseries-application`, and static cluster prerequisites are `deployment/helm/cluster-infrastructure`. The app uses a ClusterIP Service and public Ingress is disabled by default. Its NetworkPolicy denies ingress unless optional ingress is enabled and routed through the configured ingress controller.

```bash
helm upgrade --install cluster-infrastructure deployment/helm/cluster-infrastructure --namespace default --wait
kubectl create configmap bluecrest-data --from-file=data.csv=src/data/data.csv --namespace bluecrest-prod
helm upgrade --install timeseries-application deployment/helm/timeseries-application --namespace bluecrest-prod --values deployment/helm/timeseries-application/values-prod.yaml
```

NetworkPolicy enforcement depends on the cluster CNI and does not replace node/cloud firewall controls.

## GitHub Actions

- **Tests**: manual, reusable via `workflow_call`, and PR label `runTests`. `testsPassed` is published to the tested commit on main and feature branches.
- **Build image**: manual, reusable, and PR label `buildImage`. Main builds publish versioned `prod` images to GHCR; feature builds publish `dev` images tagged with branch and short commit SHA. `buildPassed` is published to the tested commit on main and feature branches.
- **Deploy**: development and production workflows run tests and build the image before deployment. Static cluster resources are bootstrapped with `apply-infrastructure`.

Ensure Actions can write packages and checks. For private GHCR images, configure an image pull secret in the target cluster.
