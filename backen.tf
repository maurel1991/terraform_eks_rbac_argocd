terraform {
  backend "s3" {
    bucket       = "w7-sk-terr-bucket"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = false
  }
}