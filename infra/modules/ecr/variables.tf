variable "name" {
  type        = string
  description = "ECR repository name."
}

variable "max_image_count" {
  type        = number
  description = "Number of images to keep; older images expire."
  default     = 10
}
