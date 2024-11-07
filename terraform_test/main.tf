provider "aws" {
 region = "ap-northeast-1"
}

resource "aws_vpc" "terra_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name: "aws_vpc_name"
    }

}