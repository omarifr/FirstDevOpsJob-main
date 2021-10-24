# aws -- version 
# aws eks  --region us-east-1 update-kubeconfig --name aforo255-cluster
# Uses default VPC  and Subnet. Create Your Own VPC and Private Subnets for 
# terraform-backend-state-aforo255
# AKIAXX4OA7XMEK5BV2GI   terraform-aws-user
# 5l93ML4r64p93dDJhpaSVbfGqHUrFZcYQYwHiB4x
#arn:aws:iam::532336934360:user/terraform-aws-user
terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnet_ids" "subnets" {
  vpc_id = aws_default_vpc.default.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
 // load_config_file       = false
 // version                = "~> 1.9"
}

module "aforo-octubreof-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "aforo-octubreof-cluster"
  cluster_version = "1.17"
  subnets         = ["subnet-04dcf0ca77d4a2d65", "subnet-0eccb5833ec744e8a", "subnet-0006dd72a1b44f835", "subnet-0407bc6e985e069f5", "subnet-0a83787fb5d4ace2b", "subnet-0716a7a0c0e0fbe3b", "subnet-030d7656c3a96aa08", "subnet-06a308c0d44399837", "subnet-092feefc07fe0c3b2", "subnet-0cb9ba872925d13d4"]  #CHANGE # Donot choose subnet from us-east-1e
  #subnets = data.aws_subnet_ids.subnets.ids
  vpc_id          = aws_default_vpc.default.id
  #vpc_id         = "vpc-1234556abcdef" 

worker_groups = [
    {
      instance_type = "t2.micro"
      asg_max_size  = 2
    }
]

}

data "aws_eks_cluster" "cluster" {
  name = module.aforo-octubreof-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.aforo-octubreof-cluster.cluster_id
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "us-east-1"
}

resource "aws_iam_role" "test_role_dev" {
  name = "test_role_dev"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
