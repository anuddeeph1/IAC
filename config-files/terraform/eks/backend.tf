terraform {
  backend "s3" {
    bucket = "eks-tf-backend-test"
    key    = "terraform/state.tfstate"
    region = "us-west-1"
  }
}
