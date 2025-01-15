# Variables
variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.7.0/24"]
}

variable "container_port_1" {
  default = 8080
}

# variable "container_port_2" {
#   default = 80
# }