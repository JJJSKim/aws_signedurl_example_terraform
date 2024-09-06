provider "aws" {
  region = "ap-northeast-2"
}
provider "tls" {

}

terraform {
  required_version = ">= 1.1.5"
  required_providers {
    aws = {
      version = ">= 4.31.0"
      source  = "hashicorp/aws"
    }
    tls = {
      version = ">= 3.0.0"
      source  = "hashicorp/tls"
    }
  }
  backend "local" {
    path = "./terraform.tfstate"
  }
}