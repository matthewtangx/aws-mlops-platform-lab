variable "name" {
  type        = string
  description = "Name prefix for network resources."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC."
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block of the single public subnet."
}

variable "availability_zone" {
  type        = string
  description = "Availability zone of the public subnet."
}
