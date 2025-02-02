output "cluster_name" {
  value = module.eks.cluster_name # Change cluster_name to cluster_id
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-west-1" # Use cluster_id instead of cluster_name
}

