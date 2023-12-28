# AWS for fluent bit
# https://artifacthub.io/packages/helm/aws/aws-for-fluent-bit

locals {
  cw-log-group = "/aws/eks/${module.eks.cluster_name}/workload"
}

resource "helm_release" "aws-for-fluent-bit" {
  depends_on = [
    module.eks
  ]

  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = ">= 0.1.29"

  namespace        = "amazon-cloudwatch"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm-values/aws-for-fluent-bit.yml", {
      region       = var.region,
      cw-log-group = local.cw-log-group
      }
    )
  ]
}
