terraform {
  required_version = ">= 1.13.0, < 1.14.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "= 2.9.1"
    }
  }
}

provider "local" {}
