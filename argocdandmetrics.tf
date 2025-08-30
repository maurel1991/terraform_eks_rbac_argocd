resource "kubernetes_manifest" "argocd_namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "argocd"
    }
  }
  depends_on = [ aws_eks_cluster.eks,aws_eks_node_group.node ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.8" # Check for the latest version
  namespace  = "argocd"

  set = [ {
    name  = "server.service.type",
    value = "LoadBalancer",
  } ]
  # Additional configurations can be added here
  # Refer to: https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml
depends_on = [ kubernetes_manifest.argocd_namespace ]
}

resource "helm_release" "metrics" {
  name       = "metric-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"
  
  set = [{
    name  = "args[0]",
    value = "--kubelet-insecure-tls"
  }]
  depends_on = [ aws_eks_cluster.eks,aws_eks_node_group.node ]
}