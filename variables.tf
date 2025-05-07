variable "my_ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}
variable "my_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
  
}
variable "my_vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "my_public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
}
variable "my_private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
}
variable "my_public_availability_zone" {
  description = "The availability zone for the public subnet"
  type        = string
}
variable "my_private_availability_zone" {
  description = "The availability zone for the private subnet"
  type        = string
}
