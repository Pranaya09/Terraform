# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "private-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "main-nat-gateway"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-route-table"
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for EC2 instance in public subnet
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Security group for EC2 instance allowing inbound from anywhere"
  vpc_id      = aws_vpc.main.id

  # Inbound rule: Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule: Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule: Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule: Allow Ping (ICMP) from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule: Allow all outbound traffic (default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the public subnet
resource "aws_instance" "public_instance" {
  ami                    = "ami-0c614dee691cbbf37"  # Replace with the correct AMI for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  tags = {
    Name = "public-instance"
  }
}

# Security Group for EC2 instance in private subnet
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Security group for EC2 instance allowing inbound from anywhere"
  vpc_id      = aws_vpc.main.id

  # Inbound rule: Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the private subnet
resource "aws_instance" "private_instance" {
  ami                    = "ami-0c614dee691cbbf37"  # Replace with the correct AMI for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  tags = {
    Name = "private-instance"
  }
}

# Create an S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "itssamplebucket"  # Replace with your desired S3 bucket name
  acl    = "private"

  versioning {
    enabled = true  # Enable versioning for the state file
  }

  tags = {
    Name        = "TerraformState"
    Environment = "Dev"
  }
}

# Create a DynamoDB table for state lock
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name         = "terraform-state-lock-dynamo"
  hash_key     = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
