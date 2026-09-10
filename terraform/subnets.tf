resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.enterprise.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-public-1a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.enterprise.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-public-1b"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app_1a" {
  vpc_id                  = aws_vpc.enterprise.id
  cidr_block              = "10.20.11.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-private-app-1a"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_app_1b" {
  vpc_id                  = aws_vpc.enterprise.id
  cidr_block              = "10.20.12.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-private-app-1b"
    Tier = "private-app"
  }
}
