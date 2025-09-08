provider "aws" {
  region = "ap-south-1"
}

# Use existing VPC
data "aws_vpc" "existing" {
  id = "vpc-0381d63c0473f8775"
}

# Get existing Internet Gateway in that VPC
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = "10.1.3.0/24" # Make sure this does not overlap with existing subnets
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet1"
  }
}

# Route Table (using existing IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.existing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing.id
  }

  tags = {
    Name = "Public-RT1"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "terraform_app_sg" {
  name   = "terraform-app-sg1"
  vpc_id = data.aws_vpc.existing.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins / App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-App-SG1"
  }
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "c7i-flex.large"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.terraform_app_sg.id]
  key_name                    = "WEBApi1"
  associate_public_ip_address = true

  tags = {
    Name = "terraform-EC23"
  }
}

# Output EC2 Public IP
output "ec2_public_ip" {
  value = aws_instance.ec2.public_ip
}
