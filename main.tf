provider "aws" {
 region = "ap-northeast-1"
}

variable "env" {
    type = string
    default = "prod"
}

variable "myip" {
    type = string
    description = "Check-> https://www.whatismyip.com/"
    default = "0.0.0.0"
}

locals{
    app_name = "handson-web"
    name_prefix = "${var.env}-${local.app_name}"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.web_vpc.id
  map_public_ip_on_launch = true

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${local.name_prefix}-public_subnet"
  }
}


resource "aws_route_table" "web_public_rtb" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_igw.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rtb"
  }
}

resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.web_vpc.id

  name        = "${local.name_prefix}-sg"
  description = "Allow HTTP access from my IP"

  ingress {
    description = "Allow HTTP traffic from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}/32"] # var.myipからのHTTPアクセスを許可
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "aws_instance" "web_ec2" {
  ami                         = "ami-094dc5cf74289dfbc" 
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.web_sg.name]

  user_data = <<-EOF
    #!/bin/bash
        dnf update -y
        dnf install -y nginx
        systemctl enable --now nginx

        cat <<HTML > /usr/share/nginx/html/index.html
            <div style="text-align:center; font-size:1.5em; color:#333; margin:20px; line-height:1.8;">
                <b>環境名: ${var.env}</b><br>
                <b>アプリ名: ${local.app_name}</b><br>
                <b>プレフィクス名: ${local.name_prefix}</b>
            </div>
        HTML
  EOF

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}
