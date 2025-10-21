# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from CloudFront"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CloudFront IPs are dynamic, so we'll restrict at listener level
  }

  ingress {
    description = "HTTPS from CloudFront"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CloudFront IPs are dynamic, so we'll restrict at listener level
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# Target Group for ECS tasks
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-backend-tg"
    Environment = var.environment
  }
}

# ALB Listener for HTTP (port 80) - only when no domain/SSL is configured
resource "aws_lb_listener" "backend_http" {
  count             = var.domain_name == "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = var.enable_private_access ? "fixed-response" : "forward"
    target_group_arn = var.enable_private_access ? null : aws_lb_target_group.backend.arn

    dynamic "fixed_response" {
      for_each = var.enable_private_access ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Access Denied: Direct access not allowed"
        status_code  = "403"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-http-listener"
    Environment = var.environment
  }
}

# HTTP Listener Rule - Allow all requests when no domain is configured and private access is disabled
resource "aws_lb_listener_rule" "backend_http_allow_all" {
  count        = var.domain_name == "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_http[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Route 53 Hosted Zone (optional - you can use existing domain)
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-zone"
    Environment = var.environment
  }
}

# Route 53 Record pointing to ALB
resource "aws_route53_record" "backend" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# SSL Certificate (optional)
resource "aws_acm_certificate" "backend" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-cert"
    Environment = var.environment
  }
}

# Certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.backend[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = aws_route53_zone.main[0].zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "backend" {
  count           = var.domain_name != "" ? 1 : 0
  certificate_arn = aws_acm_certificate.backend[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}

# HTTPS Listener (when SSL certificate is available)
resource "aws_lb_listener" "backend_https" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.backend[0].certificate_arn

  default_action {
    type             = var.enable_private_access ? "fixed-response" : "forward"
    target_group_arn = var.enable_private_access ? null : aws_lb_target_group.backend.arn

    dynamic "fixed_response" {
      for_each = var.enable_private_access ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Access Denied: Direct access not allowed"
        status_code  = "403"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-https-listener"
    Environment = var.environment
  }
}

# HTTPS Listener Rule - Allow requests from frontend domain via Origin header
resource "aws_lb_listener_rule" "backend_https_allow_frontend" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    http_header {
      http_header_name = "Origin"
      values           = ["https://${var.domain_name}"]
    }
  }
}

# HTTPS Listener Rule - Allow requests with proper referer
resource "aws_lb_listener_rule" "backend_https_allow_referer" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_https[0].arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    http_header {
      http_header_name = "Referer"
      values           = ["https://${var.domain_name}/*"]
    }
  }
}

# HTTPS Listener Rule - Allow ALB health checks
resource "aws_lb_listener_rule" "backend_https_allow_health_checks" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_https[0].arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/health/*", "/api/v1/health/"]
    }
  }
}

# HTTPS Listener Rule - Allow CloudFront health checks and direct API calls from known sources
resource "aws_lb_listener_rule" "backend_https_allow_cloudfront" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_https[0].arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    http_header {
      http_header_name = "User-Agent"
      values           = ["Amazon CloudFront"]
    }
  }
}

# Redirect HTTP to HTTPS (when SSL is enabled) - with origin restrictions
resource "aws_lb_listener" "backend_http_redirect" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_private_access ? "fixed-response" : "redirect"

    dynamic "fixed_response" {
      for_each = var.enable_private_access ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Access Denied: Direct access not allowed"
        status_code  = "403"
      }
    }

    dynamic "redirect" {
      for_each = var.enable_private_access ? [] : [1]
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-http-redirect"
    Environment = var.environment
  }
}

# HTTP Redirect Rule - Allow ALB health checks (no redirect for health endpoint)
resource "aws_lb_listener_rule" "backend_http_allow_health_checks" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_http_redirect[0].arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/health/*", "/api/v1/health/"]
    }
  }
}

# HTTP Redirect Rule - Allow requests from frontend domain
resource "aws_lb_listener_rule" "backend_http_redirect_frontend" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_http_redirect[0].arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    http_header {
      http_header_name = "Origin"
      values           = ["https://${var.domain_name}"]
    }
  }
}

# HTTP Redirect Rule - Allow requests with proper referer
resource "aws_lb_listener_rule" "backend_http_redirect_referer" {
  count        = var.domain_name != "" && var.enable_private_access ? 1 : 0
  listener_arn = aws_lb_listener.backend_http_redirect[0].arn
  priority     = 101

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    http_header {
      http_header_name = "Referer"
      values           = ["https://${var.domain_name}/*"]
    }
  }
}
