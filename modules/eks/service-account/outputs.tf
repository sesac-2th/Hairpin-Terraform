output "eks_lb_service_account_name" {
  value = kubernetes_service_account.lb_sa.metadata[0].name
}


output "eks_external_dns_service_account_name" {
  value = kubernetes_service_account.external-dns.metadata[0].name
}
