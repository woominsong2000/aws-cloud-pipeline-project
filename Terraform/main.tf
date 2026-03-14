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

# 3. (원우) 스토리지 모듈 호출
module "storage" {
  source = "./modules/storage"

  project_name   = var.project_name
  aws_account_id = var.aws_account_id
}

# 4. (원우) 메시징 모듈 호출
# bucket_notification 포함 — storage ↔ messaging 순환 의존성 해소:
# 버킷 ARN/ID를 변수로 직접 계산해서 전달 (module.storage output 불필요)

module "messaging" {
  source = "./modules/messaging"

  project_name      = var.project_name
  source_bucket_arn = "arn:aws:s3:::${var.project_name}-source-${var.aws_account_id}"
  source_bucket_id  = "${var.project_name}-source-${var.aws_account_id}"

  depends_on = [module.storage]
}