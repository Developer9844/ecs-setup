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
