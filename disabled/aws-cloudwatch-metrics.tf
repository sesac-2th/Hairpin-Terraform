# AWS CloudWatch Metrics - Container Insight
# https://artifacthub.io/packages/helm/aws/aws-cloudwatch-metrics

resource "helm_release" "aws-cloudwatch-metrics" {
  depends_on = [
    module.eks
  ]

  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = ">= 0.0.9"

  namespace        = "amazon-cloudwatch"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm-values/aws-cloudwatch-metrics.yml", {
      cluster_name = module.eks.cluster_name
      }
    )
  ]
}
