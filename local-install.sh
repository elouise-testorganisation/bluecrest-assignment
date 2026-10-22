#!/usr/bin/env bash
set -Eeuo pipefail

# Run from any directory; all paths are resolved from this script's location.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RELEASE="bluecrest"
NAMESPACE="${NAMESPACE:-default}"
IMAGE="bluecrest:local"
CHART="$ROOT_DIR/deployment/helm/timeseries-application"
DOCKERFILE="$ROOT_DIR/src/Dockerfile"
BUILD_CONTEXT="$ROOT_DIR/src"
VALUES="$CHART/values-dev.yaml"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

for cmd in docker minikube kubectl helm find; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

[[ -f "$DOCKERFILE" ]] || die "Dockerfile not found: $DOCKERFILE"
[[ -f "$VALUES" ]] || die "Helm values file not found: $VALUES"
[[ -d "$CHART/templates" ]] || die "Helm chart not found: $CHART"

# The chart expects a ConfigMap named bluecrest-data containing the key data.csv.
CSV_FILES=()
while IFS= read -r file; do
  CSV_FILES+=("$file")
done < <(find "$ROOT_DIR" -type f -name data.csv -not -path '*/.git/*' -not -path '*/.venv/*' -not -path '*/venv/*' -print)
if [[ "${#CSV_FILES[@]}" -eq 0 ]]; then
  die "Could not find data.csv anywhere in the repository. Put the app's data.csv in the repo, then rerun."
elif [[ "${#CSV_FILES[@]}" -gt 1 ]]; then
  printf 'Found more than one data.csv; choose the intended file and remove ambiguity:\n' >&2
  printf '  %s\n' "${CSV_FILES[@]}" >&2
  die "Cannot safely choose the ConfigMap source."
fi
CSV_FILE="${CSV_FILES[0]}"

printf '\n==> Starting Minikube (Docker driver)\n'
minikube start --driver=docker

printf '\n==> Building local image %s\n' "$IMAGE"
docker build -t "$IMAGE" -f "$DOCKERFILE" "$BUILD_CONTEXT"

printf '\n==> Loading image into Minikube\n'
minikube image load "$IMAGE"

printf '\n==> Creating/updating ConfigMap bluecrest-data in namespace %s\n' "$NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap bluecrest-data \
  --namespace "$NAMESPACE" \
  --from-file="data.csv=$CSV_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

printf '\n==> Installing/updating Helm release %s with the local image\n' "$RELEASE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  -f "$VALUES" \
  --set image.repository=bluecrest \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --set-json 'imagePullSecrets=[]' \
  --wait --timeout 5m

printf '\n==> Current pods and services\n'
kubectl get pods,services --namespace "$NAMESPACE" -o wide

printf '\nDeployment complete. To open the app, run this in another terminal:\n'
printf '  kubectl port-forward --namespace %q service/%q 8501:8501\n' "$NAMESPACE" "$RELEASE"
printf 'Then visit http://localhost:8501\n'
