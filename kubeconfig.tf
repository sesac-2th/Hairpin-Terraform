# Manage Kubernetes Config

locals {
  user = "${module.eks.cluster_name}-adm"
}

resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]

  # Update Kubernetes Config File
  provisioner "local-exec" {
    command = <<EOF
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --user-alias ${local.user} --alias ${module.eks.cluster_name}@${local.user} --region us-east-2
    EOF
  }

  triggers = {
    user         = local.user
    cluster_arn  = module.eks.cluster_arn
    cluster_name = module.eks.cluster_name
  }

  # terraform destroy할 때 아래의 명령이 진행됨 (나머지는 apply할 때 진행됨)
  # Remove Kubernetes Config File
  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      kubectl config delete-user ${self.triggers.user}
      kubectl config delete-cluster ${self.triggers.cluster_arn}
      kubectl config delete-context ${self.triggers.cluster_name}@${self.triggers.user}
    EOF
  }
}

output "update-kubeconfig" {
  # output "kubeconfig-update" {
  value = <<EOF
    aws eks update-kubeconfig --name ${module.eks.cluster_name} --user-alias ${local.user} --alias ${module.eks.cluster_name}@${local.user} --region us-east-2
    EOF
}

output "delete-kubeconfig" {
  # output "kubeconfig-delete" {
  value = <<EOF
    kubectl config delete-user ${local.user}
    kubectl config delete-cluster ${module.eks.cluster_arn}
    kubectl config delete-context ${module.eks.cluster_name}@${local.user}
    EOF
}