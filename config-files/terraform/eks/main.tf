module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.31"
  iam_role_arn  = "arn:aws:iam::844333597536:role/eksClusterRole-anudeep"

  # Optional: Public access to the cluster
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  create_iam_role = false
  #create_node_iam_role = false
  bootstrap_self_managed_addons = true
  
   # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids


  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      create_node_iam_role = false
      node_iam_role_arn  = "arn:aws:iam::844333597536:role/eks-anudeep-worker-node" # Using existing node role
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

## Deploying AWS Managed Add-ons separately using aws_eks_addon resource
#resource "aws_eks_addon" "vpc_cni" {
#  cluster_name  = module.eks.cluster_name
#  addon_name    = "vpc-cni"
#  addon_version = "v1.19.0-eksbuild.1"
#}
#
#resource "aws_eks_addon" "coredns" {
#  cluster_name  = module.eks.cluster_name
#  addon_name    = "coredns"
#  addon_version = "v1.11.4-eksbuild.2"
#}
#
#resource "aws_eks_addon" "kube_proxy" {
#  cluster_name  = module.eks.cluster_name
#  addon_name    = "kube-proxy"
#  addon_version = "v1.30.6-eksbuild.3"
#}

