terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.3.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }
  }
}
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"
  cluster_version = var.cluster_config.version
  cluster_name    = var.cluster_config.name
  subnets         = [aws_subnet.sb1.id, aws_subnet.sb2.id, aws_subnet.sb3.id]
  vpc_id          = aws_vpc.vpc.id
  worker_groups = [
    {
      ami_id               = var.workergroup_1.ami_id
      asg_max_size         = var.workergroup_1.asg_max_size
      asg_min_size         = var.workergroup_1.asg_min_size
      asg_desired_capacity = var.workergroup_1.asg_desired_capacity
      instance_type        = var.workergroup_1.instance_type
      key_name             = var.workergroup_1.key_name
      name                 = var.workergroup_1.name
      public_ip            = var.workergroup_1.public_ip
      root_volume_size     = var.workergroup_1.root_volume_size
      root_volume_type     = var.workergroup_1.root_volume_type
      subnets              = [aws_subnet.sb1.id, aws_subnet.sb2.id, aws_subnet.sb3.id]
    }
  ]
  worker_security_group_id = aws_security_group.workernode_sg.id
  map_users                = var.eks_config
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_id
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}
resource "kubernetes_cluster_role" "eks_user_role" {
  metadata {
    name = "eks_user_role"
  }
  rule {
    api_groups = var.user_roles.main.api_group
    resources  = var.user_roles.main.resources
    verbs      = var.user_roles.main.verbs
  }
  rule {
    api_groups = var.user_roles.apps.api_group
    resources  = var.user_roles.apps.resources
    verbs      = var.user_roles.apps.verbs
  }
  rule {
    api_groups = var.user_roles.core.api_group
    resources  = var.user_roles.core.resources
    verbs      = var.user_roles.core.verbs
  }
  rule {
    api_groups = var.user_roles.core_storage.api_groups
    resources  = var.user_roles.core_storage.resources
    verbs      = var.user_roles.core_storage.verbs
  }
}
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "terraform-example"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks_user_role"
  }
  subject {
    kind      = "Group"
    name      = "eks_user_group"
    api_group = "rbac.authorization.k8s.io"
  }
}
