module "robw_fyi_dns" {
  source = "./modules/dns"

  domain_name = local.robw_fyi.domain_name
}


# DNS Records
resource "aws_route53_record" "hooks" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = "hooks.${local.robw_fyi.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["45.63.91.217"]
}

resource "aws_route53_record" "www" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = "www.${local.robw_fyi.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["kkh7i7tgkl73.id.wasmer.app"]
}

resource "aws_acm_certificate" "robw_fyi" {
  domain_name       = "robw.fyi"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "robw_fyi_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.robw_fyi.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  zone_id = module.robw_fyi_dns.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "robw_fyi" {
  certificate_arn         = aws_acm_certificate.robw_fyi.arn
  validation_record_fqdns = [for r in aws_route53_record.robw_fyi_cert_validation : r.fqdn]
}

resource "aws_cloudfront_function" "redirect_to_www" {
  name    = "robw-fyi-redirect"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect apex to https://www.robw.fyi"
  publish = true
  code    = <<EOF
function handler(event) {
  var req = event.request;
  var qs = '';
  var query = req.querystring;
  if (query && Object.keys(query).length > 0) {
    var parts = [];
    for (var key in query) {
      if (query[key] && query[key].multiValue && query[key].multiValue.length > 0) {
        for (var i = 0; i < query[key].multiValue.length; i++) {
          parts.push(key + '=' + query[key].multiValue[i].value);
        }
      } else if (query[key] && query[key].value) {
        parts.push(key + '=' + query[key].value);
      } else {
        parts.push(key);
      }
    }
    if (parts.length > 0) {
      qs = '?' + parts.join('&');
    }
  }
  return {
    statusCode: 301,
    statusDescription: 'Moved Permanently',
    headers: { location: { value: 'https://www.robw.fyi' + req.uri + qs } }
  };
}
EOF
}

resource "aws_cloudfront_distribution" "robw_fyi" {
  enabled = true
  aliases = ["robw.fyi"]

  origin {
    domain_name = "www.robw.fyi"
    origin_id   = "dummy-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_to_www.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.robw_fyi.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.robw_fyi]
}

resource "aws_route53_record" "root_a" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = local.robw_fyi.domain_name
  type    = "A"
  ttl     = 300
  records = ["5.161.23.223"]
}

resource "aws_route53_record" "root_aaaa" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = local.robw_fyi.domain_name
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.robw_fyi.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "verify_gitlab" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = "_gitlab-pages-verification-code"
  type    = "TXT"
  ttl     = 300
  records = ["gitlab-pages-verification-code=8c81ca6d073e82a929cf051ed40bed80"]
}
