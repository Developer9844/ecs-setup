output "appLoadBalancerSecurityGroupID" {
  value = aws_security_group.appLoadBalancerSecurityGroup.id
}

output "ecsFagateSecurityGroupID" {
  value = aws_security_group.ecsFargateSecurityGroup.id
}

output "ecsEC2SecurityGroupID" {
  value = aws_security_group.ecsEC2SecurityGroup.id
}