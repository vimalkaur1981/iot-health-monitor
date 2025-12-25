# variables.tf
variable "gmail_user" {
  description = "Gmail email address used to send alerts"
  type        = string
  default     = "kaurvimal81@gmail.com"
}

variable "alert_recipient" {
  type        = string
  description = "Alert recipient email"
  default     = "learnerforlife81@gmail.com"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
}