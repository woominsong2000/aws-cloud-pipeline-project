# 1. (경락님) 네트워크 모듈 호출
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  s3_bucket_name     = var.s3_bucket_name
}

# 2. (유나) 컴퓨트 모듈 호출
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  instance_type      = var.instance_type
  
  # 경락님 network 모듈 output → 유나 compute 모듈 변수로
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
}