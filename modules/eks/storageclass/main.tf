# StorageClass for EFS
resource "kubernetes_storage_class" "efs-storage_class" {
  metadata {
    name = var.efs_name
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = var.reclaim_policy
  volume_binding_mode = var.volume_binding_mode
  parameters = {
    provisioningMode = var.provisioningMode
    fileSystemId     = var.efs_id
    directoryPerms   = var.directoryPerms
  }
}
