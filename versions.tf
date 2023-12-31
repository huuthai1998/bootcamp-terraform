terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.13.0"
    }
  }
  required_version = ">= 1.1.3"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}
