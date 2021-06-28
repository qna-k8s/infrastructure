provider "aws" {
  # Configuration options
  region = var.region
  profile = var.profile
}
variable "profile"{}
resource "aws_vpc" "vpc"{
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "vpc ${timestamp()}"
    "kubernetes.io/cluster/${var.cluster_config.name}" = "shared"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw ${timestamp()}"
  }
}
resource "aws_subnet" "sb1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = var.subnet_az[0] 
  map_public_ip_on_launch = true
  tags = {
    Name = "sb1 ${timestamp()}"
    "kubernetes.io/cluster/${var.cluster_config.name}" = "shared"
  }
}
resource "aws_subnet" "sb2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = var.subnet_az[1] 
  map_public_ip_on_launch = true
    tags = {
    Name = "sb2 ${timestamp()}"
    "kubernetes.io/cluster/${var.cluster_config.name}" = "shared"
  }
}
resource "aws_subnet" "sb3" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[2]
  availability_zone = var.subnet_az[2] 
  map_public_ip_on_launch = true
    tags = {
    Name = "sb3 ${timestamp()}"
    "kubernetes.io/cluster/${var.cluster_config.name}" = "shared"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.ig_cidr
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt ${timestamp()}"
  }
}
resource "aws_route_table_association" "rt_sb1" {
  subnet_id      = aws_subnet.sb1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rt_sb2" {
  subnet_id      = aws_subnet.sb2.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rt_sb3" {
  subnet_id      = aws_subnet.sb3.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "cluster_sg" {
  description = "Cluster security group to allow communication within the cluster(between all worker nodes and controle plane). This group is applied to control plane and all wokernodes"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow communication between within the cluster"
    from_port   = var.cluster_sg.from_port
    to_port     = var.cluster_sg.to_port
    protocol    = var.cluster_sg.protocol
    self        = var.cluster_sg.self
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster_security_group"
  }
}
resource "aws_security_group" "workernode_sg" {
  description = "Security group applied to all worker nodes"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh"
    from_port   = var.workernode_sg.ssh.from_port
    to_port     = var.workernode_sg.ssh.to_port
    protocol    = var.workernode_sg.ssh.protocol
    cidr_blocks  = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker_security_group"
    "kubernetes.io/cluster/${var.cluster_config.name}" = "owned"
  }
}
