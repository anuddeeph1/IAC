variable "cluster_name" {
  type    = string
  default = "test-eks-cluster"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "region" {
  type    = string
  default = "us-west-1"
}
