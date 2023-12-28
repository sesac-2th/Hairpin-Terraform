# Addon - AWS Load Balancer Controller
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html

module "aws_load_balancer_controller_irsa_role" {
  depends_on = [
    module.eks
  ]

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa_role.iam_role_arn
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [
    kubernetes_service_account.aws-load-balancer-controller
  ]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = ">= 1.6.0"

  values = [
    templatefile("${path.module}/helm-values/aws-load-balancer-controller.yml", {
      clusterName = module.eks.cluster_name,
      region      = "us-east-2",
      vpcId       = module.vpc.vpc_id
      }
    )
  ]
}