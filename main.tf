# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "main-vpc"
  }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2a" # Adjust based on your region
}
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b" # Adjust to a second AZ in your region
}
# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
 
  tags = {
    Name = "main-internet-gateway"
  }
}
# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
 
  tags = {
    Name = "main-public-route-table"
  }
}
 
# Associate Route Table with Subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
 
 
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow SSH access"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow RDS connections"
 
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow PostgreSQL from anywhere (adjust for more security)
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 

resource "aws_key_pair" "new_key_pair" {
  key_name   = "my-key-pair"
  public_key = file("C:/Users/boney/.ssh/id_rsa.pub")
}

# EC2 Instance
# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name = aws_key_pair.new_key_pair.key_name

  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2.id] # Reference by ID
  associate_public_ip_address = true
  tags = {
    Name = "web-instance"
  }
}

# Update DB Subnet Group to Include Both Subnets
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public_2.id]
 
  tags = {
    Name = "main-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  engine            = "postgres"
  engine_version    = "13.12"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "Rajani"
  password          = "yourPassword"
  publicly_accessible = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [ aws_security_group.rds.id ]
  skip_final_snapshot = true
 

}
output "public_ip" {
  value = aws_instance.web.public_ip
}
 output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
