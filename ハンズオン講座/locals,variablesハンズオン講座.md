ではハンズオン進めていきます。
本ハンズオンではEC2を作成し、そこにアクセスするところまで試してみます。
その過程でlocalsブロック、variableブロックを活用していきましょう

# 1. main.tfの編集

1. C:\Terrafrom\Handsonフォルダに移動
2. main.tfを編集
3. 以下の形にする。
```terraform
provider "aws" {
 region = "ap-northeast-1"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.terra_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "public_subnet"
  }
}
```
4. terraform init
5. 認証情報の設定
6. terraform plan
7. terraform apply

このままだと何のvpcか、サブネットかわからないため、各リソースにhandsonとつけたいと思います。
各リソース毎回打っていると管理が大変なので一度、localsで変数設定を行い、それを各Nameタグ内で使っていきます。

```terraform
provider "aws" {
 region = "ap-northeast-1"
}

locals{
    app_name = "web"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.app_name}-vpc"
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.terra_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${local.app_name}-public_subnet"
  }
}
```

では次にvariableブロックを利用して環境名を付けてあげましょう
今回はハンズオンですが仮にprodとつけようと思います。

```terraform
provider "aws" {
 region = "ap-northeast-1"
}

variable "env" {
    type = string
    default = "handson"
}

locals{
    app_name = "web"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.env}-${local.app_name}-vpc"
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.web_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${var.env}-${local.app_name}-public_subnet"
  }
}
```

はいではこの状態で実行してみます。

次に毎回リソースごとに${var.env}-${local.app_name}と書いていると冗長なので
name_prefixにまとめてみたいと思います。

```
provider "aws" {
 region = "ap-northeast-1"
}

variable "env" {
    type = string
    default = "prod"
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

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${local.name_prefix}-public_subnet"
  }
}

```

これですっきりしましたね！

次に以下をコピーして作成します
このTerraformのコードはパブリックサブネットの作成と
EC2インスタンスをデプロイしその中にNginxでウェブサーバを立てる構成になっています。
どのような内容かさらっと確認しましょう！

```terraform
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

resource "aws_route_table_association" "web_public_rtb_assoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_public_rtb.id
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "aws_instance" "web_ec2" {
  ami                         = "ami-094dc5cf74289dfbc" 
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.web_sg.id]
  subnet_id = aws_subnet.web_subnet.id

  user_data = <<-EOF
    #!/bin/bash
        dnf update -y
        dnf install -y nginx
        cat <<HTML > /usr/share/nginx/html/index.html
            <div style="text-align:center; font-size:1.5em; color:#333; margin:20px; line-height:1.8;">
                <b>環境名: ${var.env}</b><br>
                <b>アプリ名: ${local.app_name}</b><br>
                <b>プレフィクス名: ${local.name_prefix}</b>
            </div>
        HTML
        systemctl enable --now nginx
  EOF

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

```