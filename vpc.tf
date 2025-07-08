resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    instance_tenancy ="default"
    enable_dns_hostnames = var.enable_host_names

    tags = merge(
        var.comman_tags,
        {
            Name = "${local.resource_name}-vpc"
        }

    )
}


resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
    tags = merge(
        var.comman_tags,
        {
            Name = "${local.resource_name}--igw"

        }
    ) 

}
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    
    tags = merge(
        var.comman_tags,
        var.public_subnet_cidr_tags,
        {
            Name = "${local.resource_name}-public-${local.az_names[count.index]}"
        }
    )
}


# Private Subnets

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    
    tags = merge(
        var.comman_tags,
        var.private_subnet_cidrs_tags,
        {
            Name = "${local.resource_name}-private-${local.az_names[count.index]}"
        }
    )
}

# DATABASE SUBNETS

resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidrs)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = false
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidrs[count.index]
    
    tags = merge(
        var.comman_tags,
        var.database_subnet_cidr_tags,
        {
            Name = "${local.resource_name}-database-${local.az_names[count.index]}"
        }
    )
}

resource "aws_db_subnet_group" "default" {
    name = "${local.safe_resource_name}"
    subnet_ids = aws_subnet.database[*].id
    tags = merge(
        var.comman_tags,
        var.database_subnet_group_cidr_tags,
        {
            Name = "${local.resource_name}"
        }
    )
}
# NAT Gateway
# This will create a NAT Gateway in the first public subnet
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = merge(
        var.comman_tags,
        {
            Name = "${local.resource_name}-nat-eip"
        }
    )
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id

    tags = merge(
        var.comman_tags,
        var.nat_gateway_tags,
        {
            Name = "${local.resource_name}-nat-gw"
        }
    )
    depends_on = [aws_internet_gateway.gw]
}

#  # Route Tables
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = merge(
        var.comman_tags,
        var.route_table_public_tags,
        {
            Name = "${local.resource_name}-public-rt"
        }
    )
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.comman_tags,
        var.route_table_private_tags,
        {
            Name = "${local.resource_name}-private-rt"
        }
    )
}


resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.comman_tags,
        var.route_table_database_tags,
        {
            Name = "${local.resource_name}-database-rt"
        }
    )
}

# AWS Route
resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route" "database_route" {
    route_table_id = aws_route_table.database.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
}
# Subnet Associations
resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
    subnet_id = element(aws_subnet.public[*].id, count.index)
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count = length(aws_subnet.private)
    subnet_id = element(aws_subnet.private[*].id, count.index)
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
    count = length(aws_subnet.database)
    subnet_id = element(aws_subnet.database[*].id, count.index)
    route_table_id = aws_route_table.database.id
}

# Ec2 instance creation

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" {    # Generate "terraform-key-pair.pem" in current directory
    command = <<-EOT
      echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.generated_key_name}'.pem
      chmod 400 ./'${var.generated_key_name}'.pem
    EOT
  }

}

resource "aws_instance" "example" {
    ami = data.aws_ami.ami_info.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public[0].id
    associate_public_ip_address = true
    key_name = aws_key_pair.generated_key.key_name

    tags = merge(
        var.comman_tags,
        {
            Name = "${local.resource_name}-ec2-instance"
        }
    )

    depends_on = [
        aws_internet_gateway.gw,
        aws_nat_gateway.nat
    ]
}