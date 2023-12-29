output "eks_lb_service_account_name" {
  value = kubernetes_service_account.lb_sa.metadata[0].name
}
