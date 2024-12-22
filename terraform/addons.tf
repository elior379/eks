module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn


  enable_external_secrets = true
  enable_aws_for_fluentbit = true
    aws_for_fluentbit_cw_log_group = {
    create          = true
    auto_create_group = true
    use_name_prefix = true # Set this to true to enable name prefix
    name_prefix     = "/${local.name}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
    retention       = 7
  }
  aws_for_fluentbit = {
    name          = "aws-for-fluent-bit"
    chart_version = "0.1.28"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "podDisruptionBudget.maxUnavailable"
        value = 1
      },
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      }
    ]
    role_name   = "${module.eks.cluster_name}-alb-controller"
    policy_name = "${module.eks.cluster_name}-alb-controller"
  }
}