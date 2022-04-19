provider "aws" {
  region = "eu-west-1"
}


terraform {
  backend "s3" {
    bucket = "kozmischeheide-staging"
    key = "kozmischeheide/dev.tfstate"
    region = "eu-west-1"
    dynamodb_table = "tf-backend"
    encrypt = true
  }
}