data "aws_region" "this" {}

data "aws_route53_zone" "zone" {
  zone_id = var.zone_id
}

variable "zone_id" {
  description = "AWS Route53 Hosted Zone ID"
  type        = string
}

variable "topic_arn" {
  description = "SNS Topic ARN to send SES Bounce and Complaint notifications to"
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

locals {
  zone_name          = data.aws_route53_zone.zone.name
  notification_types = var.topic_arn != null ? ["Bounce", "Complaint"] : []
}