resource "kubernetes_service_account" "lb_sa" {
  metadata {
    name      = var.lb_service_account_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = var.lb_service_account_name
      "app.kubernetes.io/component" = var.component
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = var.lb_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "kubernetes_service_account" "external-dns" {
  metadata {
    name      = var.external_dns_sc_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.external_dns_sc_name
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = var.external_dns_role_arn
    }
  }
}

# resource "kubernetes_annotations" "efs_csi_sa" {
#   api_version = "v1"
#   kind        = "ServiceAccount"

#   for_each = toset(var.efs_service_account_name)

#   metadata {
#     name      = each.value
#     namespace = var.namespace
#   }

#   annotations = {
#     "eks.amazonaws.com/role-arn" = var.efs_role_arn
#   }
# }

# resource "kubernetes_service_account" "efs_service_account" {
#   metadata {
#     name      = "efs-csi-controller-sa"
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/name"      = "efs-csi-controller-sa"
#       "app.kubernetes.io/component" = "controller"
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn"               = var.efs_node_role_arn
#       "eks.amazonaws.com/sts-regional-endpoints" = "true"
#     }
#   }
# }

# resource "kubernetes_service_account" "efs_node_service_account" {
#   metadata {
#     name      = "efs-csi-node-sa"
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/name"      = "efs-csi-node-sa"
#       "app.kubernetes.io/component" = "node"
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn"               = var.efs_controller_role_arn
#       "eks.amazonaws.com/sts-regional-endpoints" = "true"
#     }
#   }
# }
