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