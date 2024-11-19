各コードは動画下に記載する想定です

**セリフ**
> ではハンズオン進めていきます。\
> 本ハンズオンではlocalsブロック、variableブロックの動きを確認したあと \
> EC2でウェブサーバを作成し、そこにアクセスするところまで試してみます。

> ではまずVPCとサブネットのデプロイを行っていきます。

# 1. VPC、サブネットのデプロイ
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

**セリフ**
> このままだと何のvpcか、サブネットかわからないため、ウェブサーバ関連のリソースとわかるようにリソースの名前の頭に`web`とつけたいと思います。\
> 各リソース個別に編集すると管理が大変なので一度、localsで変数設定を行い、それを各Nameタグ内で${}を用い使っていきます。\
> VSCodeを開き以下編集をおこなう

## localsブロックの活用

```terraform
provider "aws" {
 region = "ap-northeast-1"
}

# 追加
locals{
    app_name = "web"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.app_name}-vpc" # 変更
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.terra_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${local.app_name}-public_subnet" # 変更
  }
}
```

1. terraform plan
2. terraform apply
3. 名前が変わっていることの確認(vpc,サブネット)


## variableブロックの活用
> では次にvariableブロックを利用して環境名を付けてあげましょう
> 今回はハンズオン環境ですので`handson`とつけようと思います。

```terraform
provider "aws" {
 region = "ap-northeast-1"
}

# 追加
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
    Name = "${var.env}-${local.app_name}-vpc" # 変更
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.web_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${var.env}-${local.app_name}-public_subnet" # 変更
  }
}
```

**セリフ**
> はいではこの状態で実行してみます。

1. terraform plan
2. terraform apply
3. 名前が変わっていることの確認(vpc,サブネット)

## localsブロックの活用 (変数の加工)

> 次に毎回リソースごとに${var.env}-${local.app_name}と書いていると冗長なので \
> name_prefixにまとめてみたいと思います。

```
provider "aws" {
 region = "ap-northeast-1"
}

variable "env" {
    type = string
    default = "prod"
}

locals{
    app_name = "handson-web" # 追加
    name_prefix = "${var.env}-${local.app_name}"
}

resource "aws_vpc" "web_vpc" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.name_prefix}-vpc" # 変更
  }
}

resource "aws_subnet" "web_subnet" {

  vpc_id = aws_vpc.web_vpc.id

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "${local.name_prefix}-public_subnet" # 変更
  }
}

```
**セリフ**
> これですっきりしましたね！
> ではterraform planを実行していきましょう

1. terraform plan

**セリフ**
> コードは書き換えましたが、リソースの変化はないため、No Changeとでていますね！ \
> ここまででlocals,variablesの基本的な扱い方をみていきました。 


## EC2のデプロイ variableブロック変数の対話的設定の体験
**セリフ**
> では次に少し難易度上がりますが、EC2でウェブサーバを作るコードを扱ってみます \
> 以下をコピーして作成します \
> このTerraformのコードはVPCとパブリックサブネットの作成と \
> EC2インスタンスをデプロイしその中にNginxでウェブサーバを立てる構成になっています。 \
> また自分のグローバルIPアドレスをvariableブロックで設定し、セキュリティグループのインバウンドルールポート80番に許可設定をいれるようにしています。 \
> 対話モードでvariableブロックの設定を体験してみましょう！
> ではまずコードの内容を確認していきましょう！

**ポイント**　
- myipはdefaultの設定をしていないので対話モードで設定 \
- discriptionでグローバルＩＰを調べるサイトを書いているので簡単に調べられるようにしている \
- ユーザデータを用い環境変数名と変数の中身をhtmlサイトに表示するようにしている

```terraform
provider "aws" {
 region = "ap-northeast-1"
}

variable "env" {
    type = string
    default = "handson"
}

variable "myip" {
    type = string
    description = "Check-> https://www.whatismyip.com/"
}

locals{
    app_name = "web"
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
                <b>env: ${var.env}</b><br>
                <b>app_name: ${local.app_name}</b><br>
                <b>name_prefix: ${local.name_prefix}</b>
                <b>myip: ${var.myip}</b>
            </div>
        HTML
        systemctl enable --now nginx
  EOF

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}
```