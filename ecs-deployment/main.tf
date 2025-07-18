module "vpc" {
  source      = "../modules/vpc"
  ProjectName = var.ProjectName
  cidrBlock   = var.cidrBlock
}

module "securityGroups" {
  source      = "../modules/security-groups"
  ProjectName = var.ProjectName
  vpcID       = module.vpc.vpcID
}

module "appLoadBalancer" {
  source                         = "../modules/alb"
  ProjectName                    = var.ProjectName
  vpcID                          = module.vpc.vpcID
  PublicSubnetIDs                = module.vpc.PublicSubnetIDs
  appLoadBalancerSecurityGroupID = module.securityGroups.appLoadBalancerSecurityGroupID
}

module "ecsOnFargate" {
  source                    = "../modules/ecs-fargate"
  ProjectName               = var.ProjectName
  ecsFargateSecurityGroupID = module.securityGroups.ecsFagateSecurityGroupID
  fargateTargetGroupARN     = module.appLoadBalancer.fargateTargetGroupARN
  PublicSubnetIDs           = module.vpc.PublicSubnetIDs
  ContainerImage            = var.ContainerImage
  depends_on                = [module.vpc, module.appLoadBalancer]
}

# module "ecsOnEC2" {
#   source             = "../modules/ecs-ec2"
#   ProjectName        = var.ProjectName
#   ec2TargetGroupARN  = module.appLoadBalancer.ec2TargetGroupARN
#   ecsSecurityGroupID = module.securityGroups.ecsEC2SecurityGroupID
#   PublicSubnetIDs    = module.vpc.PublicSubnetIDs
#   KeyName            = var.KeyName
#   InstanceType       = var.InstanceType
#   ContainerImage     = var.ContainerImage
#   depends_on         = [module.vpc, module.appLoadBalancer, module.securityGroups]
# }

module "codeBuildProject" {
  source       = "../modules/pipeline/codebuild"
  github_token = var.github_token
  account_id   = var.account_id
  aws_region   = var.aws_region
}

module "chatappFrontendPipeline" {
  source     = "../modules/pipeline/codepipeline"
  aws_region = var.aws_region
  account_id = var.account_id
}
