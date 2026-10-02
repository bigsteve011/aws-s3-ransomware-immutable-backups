terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

# Second region for the cross-region backup copy.
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
