resource "aws_vpc_peering_connection" "peering" {
  count = var.is_vpc_peering_enabled ? 1 : 0
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = var.acceptor_vpc_id == "" ? data.aws_vpc.default.id : var.acceptor_vpc_id
    auto_accept   = var.acceptor_vpc_id != "" ? true : false
  tags = merge(
    var.comman_tags,
    var.vpc_peering_tags,
    {
      Name = "${local.resource_name}-peering"
    }
  )
  
}

resource "aws_route" "public_perring" {
    count = var.is_vpc_peering_enabled && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id            = aws_route_table.public.id
    destination_cidr_block    = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id  = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "private_perring" {
    count = var.is_vpc_peering_enabled && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id            = aws_route_table.private.id
    destination_cidr_block    = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id  = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "database_perring" {
    count = var.is_vpc_peering_enabled && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id            = aws_route_table.database.id
    destination_cidr_block    = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id  = aws_vpc_peering_connection.peering[0].id
}
