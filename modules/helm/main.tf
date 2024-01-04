resource "helm_release" "lb" {
  name       = var.helm_lb_name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.namespace

  dynamic "set" {
    for_each = {
      "clusterName"           = var.eks_cluster_name
      "serviceAccount.create" = "false"
      "serviceAccount.name"   = var.eks_lb_service_account_name
      "region"                = var.lb_deploy_region
      "vpcId"                 = var.vpc_id
      "image.repository"      = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "external-dns" {

  name       = var.helm_external_dns_name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.namespace
  # version    = ">= 1.13.0"

  dynamic "set" {
    for_each = {
      "clusterName"           = var.eks_cluster_name
      "serviceAccount.create" = "false"
      "serviceAccount.name"   = var.eks_external_dns_service_account_name
      "region"                = var.external_dns_deploy_region
      "vpcId"                 = var.vpc_id
      "policy"                = "sync"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "kubernetes_namespace" "ArgoCD" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "Jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "helm_release" "ArgoCD" {
  depends_on = [
    kubernetes_namespace.ArgoCD
  ]
  name       = var.helm_argocd_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.ArgoCD.metadata.0.name
  values     = [file("${path.module}/helm-values/argocd-values.yaml")]
}

# jenkins
resource "helm_release" "Jenkins" {
  depends_on = [
    kubernetes_namespace.Jenkins
  ]
  name       = var.helm_jenkins_name
  repository = "https://charts.jenkins.io/"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.Jenkins.metadata.0.name
  values     = [file("${path.module}/helm-values/jenkins-values.yaml")] # 실행되는 root main 기준으로 디렉토리 경로 작성
}

# resource "helm_release" "metrics-server" {
#   # depends_on = [ module.eks ]

#   name = "metrics-server"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   chart = "metrics-server"
#   namespace = "kube-system"
#   version = ">= 3.11.0"
# }