# variables.tf
variable "GMAIL_USER" { 
    type = string 
    default     = null
}
variable "GMAIL_APP_PASSWORD" { 
    type = string 
    default     = null
}

variable "ALERT_RECIPIENT" { 
    type = string 
    default = "learnerforlife81@example.com"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "uat"
}

variable "alert_image_tag" {
  type        = string
  description = "Docker image tag for the alert service. Passed from GitHub workflow."
  default     = "latest"
}

variable "consumer_image_tag" {
  type        = string
  description = "Docker image tag for the alert service. Passed from GitHub workflow."
  default     = "latest"
}

variable "producer_image_tag" {
  type        = string
  description = "Docker image tag for the alert service. Passed from GitHub workflow."
  default     = "latest"
}