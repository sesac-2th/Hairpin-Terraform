# ArgoCD
# https://argo-cd.readthedocs.io/en/stable/
# https://artifacthub.io/packages/helm/argo/argo-cd
# https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
# https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd#ha-mode-without-autoscaling

resource "helm_release" "argo-cd" {
  depends_on = [
    module.eks,
    resource.helm_release.aws-load-balancer-controller
  ]

  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  # version    = ">= 1.4.1"

  namespace        = "argocd"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm-values/argo-cd.yml", {})
  ]
}

output "argocd_init_password" {
  description = "ArgoCD Initial Admin Password"
  value       = <<EOF
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo"
    EOF
}

data "kubernetes_ingress_v1" "argocd" {
  depends_on = [ 
    resource.helm_release.argo-cd
  ]

  metadata {
    name      = "argo-argocd-server"
    namespace = "argocd"
  }
}

output "argocd_url" {
  description = "URL of ArgoCD Dashboard"
  value       = "http://${data.kubernetes_ingress_v1.argocd.status.0.load_balancer.0.ingress.0.hostname}"
}
