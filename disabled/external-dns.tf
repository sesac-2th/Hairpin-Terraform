# https://github.com/kubernetes-sigs/external-dns
# https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
# https://artifacthub.io/packages/helm/external-dns/external-dns


module "external_dns_irsa_role" {
  depends_on = [
    module.eks
  ]

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                  = "external-dns"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "kubernetes_service_account" "external-dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "external-dns"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa_role.iam_role_arn
    }
  }
}

resource "helm_release" "external-dns" {
  depends_on = [
    module.external_dns_irsa_role
  ]

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  # version    = ">= 1.13.0"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
}
