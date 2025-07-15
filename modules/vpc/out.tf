output "vpcID" {
  value = aws_vpc.vpc.id
}

output "PublicSubnetIDs" {
  value = [aws_subnet.public[0].id, aws_subnet.public[1].id]
}
output "PrivateSubnetIDs" {
  value = [aws_subnet.private[0].id, aws_subnet.private[1].id]
}