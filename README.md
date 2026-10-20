# Bluecrest time-series app

A minimal Streamlit application that reads `src/data.csv` on startup and plots numeric time series against a `date` column.

## Local development

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r src/requirements.txt
cd src
streamlit run app.py
```

Populate `src/data.csv` with a header such as `date,value` and rows of ISO dates and numeric values. The CSV is intentionally empty in this initial commit.

Run tests with `cd src && python -m unittest discover -v`.

## Container

```bash
docker build -t bluecrest:dev ./src
docker run --rm -p 8501:8501 -v "$PWD/src/data.csv:/app/data.csv:ro" bluecrest:dev
```

## Kubernetes / Helm

The versioned Helm chart is in `deployment/helm/bluecrest` (chart version `0.1.0`). It defines a Deployment and ClusterIP Service. Before deploying, create a ConfigMap named `bluecrest-data` containing a `data.csv` key. The chart mounts that key read-only at `/app/data.csv`.

```bash
kubectl create configmap bluecrest-data --from-file=data.csv=src/data.csv
helm upgrade --install bluecrest deployment/helm/bluecrest --namespace bluecrest --create-namespace
```

The deploy workflow currently validates the chart and intentionally skips cluster deployment until a real cluster is available.

## GitHub Actions

- **Tests**: manual, reusable via `workflow_call`, and PR label `runTests`. Feature PR runs publish a `testsPassed` check against the exact tested head SHA.
- **Build image**: manual, reusable, and PR label `buildImage`. Main builds publish versioned `prod` images to GHCR; feature builds publish `dev` images tagged with branch and short commit SHA. Feature PR runs publish a `buildPassed` check against the tested SHA.
- **Deploy**: runs on pushes to `main`, manual dispatch with a ref, or PR label `deployDev`; it runs tests, builds the image, and lints the chart before logging that the fictional-cluster deployment was skipped.

Ensure the repository's Actions settings permit workflows to write packages and checks. For private GHCR images, configure an image pull secret in the target cluster when one exists.
