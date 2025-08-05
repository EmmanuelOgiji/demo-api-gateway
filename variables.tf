variable "name" {
  description = "Logical name for resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-west-1"
}

variable "access_key" {
  description = "IAM Access key"
  type        = string
}

variable "secret_key" {
  description = "IAM secret key"
  type        = string
}
