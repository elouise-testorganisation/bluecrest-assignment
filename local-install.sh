#!/usr/bin/env bash
set -Eeuo pipefail

# Local Minikube deployment:
#   1. Enable cluster-level metrics support (required by the production HPA).
#   2. Install the production-configured release into its own namespace.
#   3. Install one disposable development release into a separate namespace.
#
# Both releases use the locally built image so this script does not require
# GHCR credentials. This is a local rehearsal, not a real production rollout.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CHART="$ROOT_DIR/deployment/helm/timeseries-application"
DOCKERFILE="$ROOT_DIR/src/Dockerfile"
BUILD_CONTEXT="$ROOT_DIR/src"
IMAGE="bluecrest:local"
PROD_NAMESPACE="${PROD_NAMESPACE:-production}"
DEV_NAMESPACE="${DEV_NAMESPACE:-transient-dev}"
PROD_RELEASE="${PROD_RELEASE:-bluecrest-prod}"
DEV_RELEASE="${DEV_RELEASE:-bluecrest-dev}"
CLEAN_DEV="${CLEAN_DEV:-false}"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

for cmd in docker minikube kubectl helm find; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

[[ -f "$DOCKERFILE" ]] || die "Dockerfile not found: $DOCKERFILE"
[[ -f "$CHART/Chart.yaml" ]] || die "Helm chart not found: $CHART"
[[ -f "$CHART/values-prod.yaml" ]] || die "Production values file not found."
[[ -f "$CHART/values-dev.yaml" ]] || die "Development values file not found."
[[ "$PROD_NAMESPACE" != "$DEV_NAMESPACE" ]] || die "Production and development namespaces must differ."
[[ "$PROD_RELEASE" != "$DEV_RELEASE" ]] || die "Production and development release names must differ."

# The chart mounts a ConfigMap key named data.csv. Require one unambiguous source.
CSV_FILES=()
while IFS= read -r file; do
  CSV_FILES+=("$file")
done < <(find "$ROOT_DIR" -type f -name data.csv \
  -not -path '*/.git/*' -not -path '*/.venv/*' -not -path '*/venv/*' -print)

if [[ "${#CSV_FILES[@]}" -eq 0 ]]; then
  die "Could not find data.csv in the repository."
elif [[ "${#CSV_FILES[@]}" -gt 1 ]]; then
  printf 'Found multiple data.csv files; choose one before running:\n' >&2
  printf '  %s\n' "${CSV_FILES[@]}" >&2
  die "Cannot safely choose the ConfigMap source."
fi
CSV_FILE="${CSV_FILES[0]}"

printf '\n==> Starting Minikube\n'
minikube start --driver=docker

printf '\n==> Enabling metrics-server for production autoscaling\n'
minikube addons enable metrics-server

printf '\n==> Building local image %s\n' "$IMAGE"
docker build -t "$IMAGE" -f "$DOCKERFILE" "$BUILD_CONTEXT"

printf '\n==> Loading image into Minikube\n'
minikube image load "$IMAGE"

ensure_namespace() {
  kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f -
}

ensure_data_configmap() {
  local namespace="$1"
  kubectl create configmap bluecrest-data \
    --namespace "$namespace" \
    --from-file="data.csv=$CSV_FILE" \
    --dry-run=client -o yaml | kubectl apply -f -
}

printf '\n==> Installing production-configured release in namespace %s\n' "$PROD_NAMESPACE"
ensure_namespace "$PROD_NAMESPACE"
ensure_data_configmap "$PROD_NAMESPACE"
helm upgrade --install "$PROD_RELEASE" "$CHART" \
  --namespace "$PROD_NAMESPACE" \
  -f "$CHART/values-prod.yaml" \
  --set image.repository=bluecrest \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --set-json 'imagePullSecrets=[]' \
  --wait --timeout 5m

printf '\n==> Installing one transient development release in namespace %s\n' "$DEV_NAMESPACE"
ensure_namespace "$DEV_NAMESPACE"
ensure_data_configmap "$DEV_NAMESPACE"
helm upgrade --install "$DEV_RELEASE" "$CHART" \
  --namespace "$DEV_NAMESPACE" \
  -f "$CHART/values-dev.yaml" \
  --set image.repository=bluecrest \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --set-json 'imagePullSecrets=[]' \
  --wait --timeout 5m

printf '\n==> Deployment status\n'
kubectl get pods,services,hpa --namespace "$PROD_NAMESPACE" -o wide
kubectl get pods,services,hpa --namespace "$DEV_NAMESPACE" -o wide

printf '\nProduction app port-forward (run in a separate terminal):\n'
printf '  kubectl port-forward --namespace %q service/%q 8501:8501\n' "$PROD_NAMESPACE" "$PROD_RELEASE"
printf 'Development app port-forward (use another terminal/port):\n'
printf '  kubectl port-forward --namespace %q service/%q 8502:8501\n' "$DEV_NAMESPACE" "$DEV_RELEASE"
printf '\nVisit http://localhost:8501 (production config) or http://localhost:8502 (development config).\n'

if [[ "$CLEAN_DEV" == "true" ]]; then
  printf '\n==> CLEAN_DEV=true: removing transient development release and namespace\n'
  helm uninstall "$DEV_RELEASE" --namespace "$DEV_NAMESPACE"
  kubectl delete namespace "$DEV_NAMESPACE" --wait=true
fi
