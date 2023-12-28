# Addon - Cluster Autoscaler
# https://github.com/kubernetes/autoscaler
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
# https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/

module "cluster_autoscaler_irsa_role" {
  depends_on = [
    module.eks
  ]

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

resource "helm_release" "cluster-autoscaler" {
  depends_on = [
    module.cluster_autoscaler_irsa_role
  ]

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = ">= 9.29.0"

  values = [
    templatefile("${path.module}/helm-values/cluster-autoscaler.yml", {
      cluster_name = module.eks.cluster_name,
      region       = var.region,
      role_arn     = module.cluster_autoscaler_irsa_role.iam_role_arn
      }
    )
  ]
}
