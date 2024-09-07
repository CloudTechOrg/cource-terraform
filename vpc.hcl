resource "aws_vpc" "HandsonVPC" {
  cidr_block           = "10.0.0.0/21"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.AWS_StackName}-vpc"
  }
}

variable "AWS_StackName" {
  type    = string
  default = "YourStackNameHere"
}
