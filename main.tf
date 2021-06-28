terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }
  }
}
resource "aws_iam_role" "cluster_role" {
  name = "qna_cluster_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_role_policy_attachment" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "cluster_eks_service_role_policy_attachment" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
resource "aws_iam_role_policy_attachment" "cluster_vpc_role_policy_attachment" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role" "worker_node_role" {
  name = "qna_worker_node_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "worker_node_role_policy_attachment" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "worker_node_role_ECR_policy_attachment" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "worker_node_role_CNI_policy_attachment" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_cluster" "qna_cluster" {
  name = var.cluster_config.name
  role_arn = aws_iam_role.cluster_role.arn
  version = var.cluster_config.version
  depends_on = [
    aws_iam_role_policy_attachment.cluster_role_policy_attachment,
    aws_iam_role_policy_attachment.cluster_eks_service_role_policy_attachment,
    aws_iam_role_policy_attachment.cluster_vpc_role_policy_attachment,
    aws_security_group.cluster_sg,
  ]
  vpc_config {
    subnet_ids = [aws_subnet.sb1.id, aws_subnet.sb2.id, aws_subnet.sb3.id ]
  }
}
resource "aws_eks_node_group" "worker_node" {
  cluster_name    = aws_eks_cluster.qna_cluster.name
  node_group_name = "qna_worker_node"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = [aws_subnet.sb1.id,aws_subnet.sb2.id,aws_subnet.sb3.id]

  scaling_config {
    desired_size = var.workergroup_1.asg_desired_capacity
    max_size     = var.workergroup_1.asg_max_size
    min_size     = var.workergroup_1.asg_min_size
  }
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]
  remote_access {
    ec2_ssh_key = var.workergroup_1.key_name
  }
  depends_on = [
    aws_eks_cluster.qna_cluster,
    aws_iam_role_policy_attachment.worker_node_role_policy_attachment,
    aws_iam_role_policy_attachment.worker_node_role_ECR_policy_attachment,
    aws_iam_role_policy_attachment.worker_node_role_CNI_policy_attachment,
  ]
}
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.qna_cluster.name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.qna_cluster.name
}

