locals {
  name                = "eks-cluster"
  region              = "us-east-1"
  eks_cluster_version = "1.31"

  vpc_cidr = "10.42.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name = local.name
  }
}