resource "aws_internet_gateway" "enterprise" {
  vpc_id = aws_vpc.enterprise.id

  tags = {
    Name = "igw-enterprise-dev"
  }
}
