# Addon - Metrics-server
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/metrics-server.html

resource "helm_release" "metrics-server" {
  depends_on = [
    module.eks
  ]

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = ">= 3.11.0"
}