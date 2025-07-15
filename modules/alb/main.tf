resource "aws_lb" "applicationLoadBalancer" {
  name               = "${var.ProjectName}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.appLoadBalancerSecurityGroupID]
  subnets            = concat(var.PublicSubnetIDs)

}

resource "aws_lb_target_group" "fargateTargetGroup" {
  name            = "${var.ProjectName}-FargateTargetGroup"
  target_type     = "ip" # "instance", "lambda"
  port            = 3000 # container port
  protocol        = "HTTP"
  ip_address_type = "ipv4"
  vpc_id          = var.vpcID
  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-302"
  }
}

resource "aws_lb_listener" "fargateListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroup.arn
  }
}



#####################################

# resource "aws_lb_target_group" "ec2TargetGroup" {
#   name            = "${var.ProjectName}-EC2-Target-Group"
#   target_type     = "instance" # "ip", "lambda"
#   port            = 3000       # container port
#   protocol        = "HTTP"
#   ip_address_type = "ipv4"
#   vpc_id          = var.vpcID
#   health_check {
#     protocol            = "HTTP"
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#     matcher             = "200-302"
#   }
# }

# resource "aws_lb_listener" "ec2Listener" {
#   load_balancer_arn = aws_lb.applicationLoadBalancer.arn
#   port              = 80
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ec2TargetGroup.arn
#   }
# }