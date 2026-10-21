# Deployment and cluster prerequisites

All Helm charts are kept under `deployment/helm`:

- `deployment/helm/timeseries-application` deploys the Streamlit application.
- `deployment/helm/cluster-infrastructure` provisions static cluster prerequisites: the production namespace, ResourceQuota, and ingress NetworkPolicies.

Bootstrap the static prerequisites with:

```bash
helm upgrade --install cluster-infrastructure deployment/helm/cluster-infrastructure --namespace default --wait
```

The application chart defaults to a `ClusterIP` Service and has public Ingress disabled. Its NetworkPolicy denies ingress to application pods by default. To publish the app, set `ingress.enabled: true`, configure a real host and TLS, and ensure the installed ingress controller is the only route to the service. The policy allows the configured ingress-controller namespace and controller pods on TCP 8501 only. A CNI that enforces Kubernetes NetworkPolicy is required.

The cluster chart's production namespace policy denies ingress by default and permits the ingress controller to reach Bluecrest on TCP 8501. NetworkPolicies constrain pod traffic; they do not replace host/cloud firewall rules. Do not expose the Kubernetes API publicly.

The `apply-infrastructure` workflow creates the GHCR image-pull secret from GitHub Actions secrets. Per-deployment data ConfigMaps and transient development namespaces remain managed by deployment workflows. The bootstrap runner must be a trusted self-hosted runner on the same machine/network as Minikube; Minikube is not automatically reachable from the public internet.
