# Cluster bootstrap

Apply the static cluster prerequisites with `helm upgrade --install bluecrest-cluster infrastructure/helm/bluecrest-cluster --namespace default`.

All infrastructure resources scoped to the persistent production namespace are grouped in `infrastructure/helm/bluecrest-cluster/templates/prod-namespace.yaml`: the namespace, ResourceQuota, and ingress network policies. The application chart owns its pod/container configuration (including the LimitRange, security context, probes, resource requests/limits) and the optional public Ingress resource in `deployment/helm/bluecrest/templates/public-ingress.yaml`.

Public exposure is opt-in. Set `ingress.enabled: true` and replace the sample host in the relevant values file with a real DNS name. A reachable ingress controller must be installed and configured, DNS must point to the cluster's public endpoint, and TLS should be configured before production use. For Minikube, enable its ingress addon for local testing; Minikube is not automatically reachable from the public internet. The production default-deny network policy allows ingress-nginx traffic to the Bluecrest app on TCP port 8501.

The `apply-infrastructure` workflow also creates the GHCR image-pull secret from GitHub Actions secrets. Per-deployment data ConfigMaps and transient development namespaces are managed by the deployment workflows, not this chart.

The runner must be a trusted self-hosted runner on the same machine/network as Minikube. Do not expose the Kubernetes API publicly.
