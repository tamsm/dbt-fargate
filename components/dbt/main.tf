module "dbt_labels" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"

  stage     = "dev"
  namespace = "kh"
  name      = "dbt"
  delimiter = "-"

  tags = {
    "ApplicationType" = "Analytics"
  }
}