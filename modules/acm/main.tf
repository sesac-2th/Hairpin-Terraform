resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = try(var.alternative_name, null)
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
# ==== 인증서 검증을 위한 Route53 레코드 등록 ====
resource "aws_route53_record" "record" {
  depends_on = [aws_acm_certificate.cert]
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_host_zone
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}

