variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for data, models and metrics."
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days before noncurrent object versions are deleted."
  default     = 30
}
