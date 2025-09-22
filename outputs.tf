# MSK Outputs
output "msk_bootstrap_brokers" {
  description = "MSK bootstrap brokers"
  value       = module.msk.msk_bootstrap_brokers
}

output "msk_cluster_arn" {
  description = "MSK cluster ARN"
  value       = module.msk.msk_cluster_arn
}

output "msk_config_arn" {
  description = "MSK configuration ARN"
  value       = module.msk.msk_config_arn
}

# EKS Outputs
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}