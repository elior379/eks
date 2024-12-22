module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.1"

  cluster_name    = local.name
  cluster_version = local.eks_cluster_version

  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    coredns                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true",
        env = {
          ENABLE_POD_ENI                    = "true",
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
          ENABLE_PREFIX_DELEGATION          = "true"
      } })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi.arn
    }
    aws-efs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.efs_csi.arn
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    master = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]

      min_size     = 2
      max_size     = 4
      desired_size = 2

      taints = {
        dedicated = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })

  tags = local.tags
}
resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}