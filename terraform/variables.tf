# variables.tf
variable "GMAIL_USER" {
  type        = string
  description = "Gmail username"
  sensitive   = true
}

variable "GMAIL_APP_PASSWORD" {
  type        = string
  description = "Gmail app password"
  sensitive   = true
}

variable "ALERT_RECIPIENT" {
  type        = string
  description = "Alert recipient email"
}