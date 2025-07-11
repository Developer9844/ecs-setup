module "vpc" {
  source       = "../modules/vpc"
  project_name = var.project_name
  cidr_block   = var.cidr_block
}

module "alb" {
  source             = "../modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpcID
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "ecsOnFargate" {
  source               = "../modules/fargate"
  project_name         = var.project_name
  vpc_id               = module.vpc.vpcID
  alb_sg               = module.alb.alb_sg
  container_image      = var.container_image
  public_subnet_ids    = module.vpc.public_subnet_ids
  alb_target_group_arn = module.alb.alb_target_group_arn
  depends_on           = [module.vpc, module.alb]
}
