module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"
  name    = "kozmischeheide-dev"
  cidr    = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

locals {
  repository_root = "${path.cwd}/../../.."
  dbt_dir         = "projects"
  project_dir     = "${local.repository_root}/${local.dbt_dir}"
  executions      = [
    {
      process = "default-model", schedule = "cron(15 4 * * ? *)", command = ["compile", "--profiles-dir", "/usr/app/"]
    },
    { process = "hourly-models", schedule = "cron(30 * * * ? *)", command = ["run", "--profiles-dir", "/usr/app/"] }
  ]

}

module "dbt" {
  source      = "../../../components/dbt"
  region      = "eu-west-1"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  subnet_arns = module.vpc.private_subnet_arns
  project_dir = local.project_dir
  dbt_dir     = local.dbt_dir
  executions  = local.executions
}
