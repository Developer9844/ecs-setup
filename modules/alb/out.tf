output "fargateTargetGroupARN" {
  value = aws_lb_target_group.fargateTargetGroup.arn
}
# output "ec2TargetGroupARN" {
#   value = aws_lb_target_group.ec2TargetGroup.arn
# }