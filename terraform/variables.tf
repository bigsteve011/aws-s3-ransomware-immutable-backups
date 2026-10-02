variable "primary_region" {
  type    = string
  default = "eu-west-1"
}

variable "dr_region" {
  type    = string
  default = "eu-central-1"
}

variable "bucket_name" {
  description = "Globally unique name for the immutable records bucket."
  type        = string
}

variable "retention_days" {
  description = "COMPLIANCE-mode retention. Nobody, including root, can delete or shorten it."
  type        = number
  default     = 90
}

variable "backup_admin_role_arns" {
  description = "IAM roles allowed to administer the KMS keys (break-glass/security team)."
  type        = list(string)
}
