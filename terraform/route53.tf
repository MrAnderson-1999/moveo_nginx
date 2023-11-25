# Create a DNS record for the root domain (humanity-project.com) pointing to the ALB
resource "aws_route53_record" "root_record" {
  zone_id = var.existing_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.my_alb.dns_name
    zone_id                = aws_lb.my_alb.zone_id
    evaluate_target_health = true
  }
}


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.my_cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      value   = dvo.resource_record_value
    }
  }

  zone_id = var.existing_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate" "my_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.my_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
