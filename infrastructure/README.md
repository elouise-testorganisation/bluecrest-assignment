# Cluster bootstrap

Apply the static cluster prerequisites with `helm upgrade --install bluecrest-cluster infrastructure/helm/bluecrest-cluster --namespace default`.

The chart creates the persistent production namespace and its resource controls. The bootstrap workflow also creates the GHCR image-pull secret from GitHub Actions secrets. Per-deployment data ConfigMaps and transient development namespaces are managed by the deployment workflows, not this chart.

The runner must be a trusted self-hosted runner on the same machine/network as Minikube. Do not expose the Kubernetes API publicly.
