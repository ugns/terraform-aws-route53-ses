resource "aws_ses_domain_identity" "this" {
  domain = local.zone_name
}

resource "aws_ses_domain_dkim" "this" {
  domain = local.zone_name
}

resource "aws_route53_record" "amazonses" {
  allow_overwrite = true
  zone_id         = var.zone_id
  name            = "_amazonses"
  type            = "TXT"
  ttl             = 1800
  records         = [aws_ses_domain_identity.this.verification_token]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_ses_domain_identity_verification" "this" {
  domain = local.zone_name

  depends_on = [aws_route53_record.amazonses]
}

resource "aws_route53_record" "dkim_token" {
  count = 3

  allow_overwrite = true
  zone_id         = var.zone_id
  name            = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey"
  type            = "CNAME"
  ttl             = 600
  records         = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_ses_identity_notification_topic" "this" {
  for_each = toset(local.notification_types)

  topic_arn                = var.topic_arn
  notification_type        = each.value
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = true
}

resource "aws_ses_domain_mail_from" "this" {
  domain           = local.zone_name
  mail_from_domain = "bounce.${aws_ses_domain_identity.this.domain}"
}

resource "aws_route53_record" "ses_mail_from_mx" {
  allow_overwrite = true
  zone_id         = var.zone_id
  name            = aws_ses_domain_mail_from.this.mail_from_domain
  type            = "MX"
  ttl             = 600
  records         = ["10 feedback-smtp.${data.aws_region.this.name}.amazonses.com"]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_route53_record" "ses_mail_from_txt" {
  allow_overwrite = true
  zone_id         = var.zone_id
  name            = aws_ses_domain_mail_from.this.mail_from_domain
  type            = "TXT"
  ttl             = 600
  records         = ["v=spf1 include:amazonses.com -all"]

  lifecycle {
    create_before_destroy = false
  }
}

