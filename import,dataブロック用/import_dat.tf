# import {
#   to = aws_instance.example
#   id = "i-abcd1234"
# }


# data "aws_vpc" "default_vpc" {
#   default = true
# }

data "aws_eip" "example" {
  id = "eipalloc-0d512f76124a2992e"
}

output "eip_public_ip" {
  value = data.aws_eip.example.public_ip
}