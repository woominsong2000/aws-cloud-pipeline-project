# 1. (경락님) 네트워크 모듈 호출
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  region             = var.aws_region
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

# 2. (원우) 스토리지 모듈 호출
module "storage" {
  source = "./modules/storage"

  project_name   = var.project_name
  aws_account_id = var.aws_account_id
}

# 3. (원우) 메시징 모듈 호출
module "messaging" {
  source = "./modules/messaging"

  project_name      = var.project_name
  source_bucket_arn = module.storage.source_bucket_arn
  source_bucket_id  = module.storage.source_bucket_id
}

# 4. (유나) 컴퓨트 모듈 호출
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  instance_type         = var.instance_type

  # 경락님 network 모듈 output
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # 원우 storage 모듈 output
  ecr_repository_url = module.storage.ecr_repository_url
}