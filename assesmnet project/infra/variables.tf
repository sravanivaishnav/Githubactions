variable "project_name" {
  description = "Project name used in resource names"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Deployment environment (dev/test/prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}
