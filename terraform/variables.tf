# Variables
variable "region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.7.0/24"]
}
variable "private_subnet_cidrs"{
  default = ["10.0.5.0/24", "10.0.2.0/24"]
}

variable "container_port_1" {
  default = 3000
}

variable "certificate_arn" {
  default="arn:aws:acm:ap-south-1:207990345110:certificate/6647cbd9-a848-46fc-a820-a8fef3cdea89"
}

variable "account_id" {
  default= "207990345110"
}