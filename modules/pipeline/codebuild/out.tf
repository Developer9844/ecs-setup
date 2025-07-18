output "connection_id" {
  value = local.connection_id
}


output "codeconnect_arn" {
  value = data.aws_codestarconnections_connection.github.arn
}
