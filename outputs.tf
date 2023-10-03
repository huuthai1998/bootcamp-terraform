output "codecommit_repo_url" {
  description = "Codecommit repo name"
  value       = aws_codecommit_repository.bootcamp.repository_name
}

output "test" {
  description = "asdf repo name"
  value       = module.eks_cluster.pod_exec_role_arn
}
output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.bootcamp.endpoint
}
