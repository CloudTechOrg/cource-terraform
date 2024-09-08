provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example_vpc"
  }
}

resource "aws_subnet" "example_subnet" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "example_subnet"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c6359fd9eb30edcf"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example_subnet.id

  tags = {
    Name = "hogeeInstance"
  }
}
