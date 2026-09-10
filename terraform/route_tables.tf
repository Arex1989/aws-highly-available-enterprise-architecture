resource "aws_route_table" "public" {
  vpc_id = aws_vpc.enterprise.id

  tags = {
    Name = "rtb-public-enterprise-dev"
  }
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.enterprise.id

  tags = {
    Name = "rtb-private-app-enterprise-dev"
  }
}
