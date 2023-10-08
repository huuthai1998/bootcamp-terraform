output "codecommit_http_clone_repo_url" {
  description = "Codecommit repo clone http"
  value       = aws_codecommit_repository.bootcamp.clone_url_http
}

output "test" {
  description = "asdf repo name"
  value       = module.eks_cluster.pod_exec_role_arn
}
output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.bootcamp.endpoint
}
