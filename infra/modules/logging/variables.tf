variable "name" {
  type        = string
  description = "CloudWatch log group name."
}

variable "retention_days" {
  type        = number
  description = "Log retention in days."
  default     = 14
}
