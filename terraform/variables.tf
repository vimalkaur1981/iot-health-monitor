# variables.tf
variable "GMAIL_USER" { 
    type = string 
}
variable "GMAIL_APP_PASSWORD" { 
    type = string 
}

variable "ALERT_RECIPIENT" { 
    type = string 
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "uat"
}