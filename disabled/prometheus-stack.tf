# kube-prometheus-stack
# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack

resource "helm_release" "kube-prometheus-stack" {
  depends_on = [
    module.eks,
    resource.helm_release.aws-load-balancer-controller
  ]

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  # version    = "~> 49.2.0"

  namespace        = "monitor"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm-values/prometheus-stack.yml", {})
  ]
}

data "kubernetes_ingress_v1" "grafana" {
  depends_on = [ 
    resource.helm_release.kube-prometheus-stack
  ]
  
  metadata {
    name = "kube-prometheus-stack-grafana"
    namespace = "monitor"
  }
}

output "grafana_url" {
  description = "URL of Grafana Dashboard"
  value = "http://${data.kubernetes_ingress_v1.grafana.status.0.load_balancer.0.ingress.0.hostname}/login"
}
