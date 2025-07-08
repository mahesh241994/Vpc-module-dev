data "aws_availability_zones" "available" {
  state = "available"
}


data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_ami" "ami_info" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250610"]

  }
  owners = ["099720109477"]
}
