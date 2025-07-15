# --- ECS Node Role ---

data "aws_iam_policy_document" "ecsAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsInstanceRole" {
  name_prefix        = var.ProjectName
  assume_role_policy = data.aws_iam_policy_document.ecsAssumeRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "ecsInstanceRolePolicy" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecsInstanceProfile" {
  name = "${var.ProjectName}-Instance-Profile"
  role = aws_iam_role.ecsInstanceRole.name
}



data "aws_ssm_parameter" "ecsLinuxAMI" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}



resource "aws_launch_template" "ecsLaunchTemplate" {
  name_prefix   = "${var.ProjectName}-ECS-Launch-Template"
  image_id      = data.aws_ssm_parameter.ecsLinuxAMI.value
  instance_type = var.InstanceType
  key_name      = var.KeyName
  iam_instance_profile {
    name = aws_iam_instance_profile.ecsInstanceProfile.name
  }
  user_data = .(<<-EOF
      #!/bin/bash 
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )
  vpc_security_group_ids = [var.ecsSecurityGroupID]
  block_device_mappings {
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
    device_name = "/dev/sdf"
  }
}


resource "aws_autoscaling_group" "ecsAutoScalingGroup" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.PublicSubnetIDs

  launch_template {
    id      = aws_launch_template.ecsLaunchTemplate.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ECS-Instance"
    propagate_at_launch = true
  }
}




resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_capacity_provider" "capacityProvider" {
  name = "${var.ProjectName}-CP"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecsAutoScalingGroup.arn
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }
    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.capacityProvider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.capacityProvider.name
    base              = 1
    weight            = 100
  }
}






resource "aws_ecs_task_definition" "chatapp" {
  family                   = "chatapp"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "chatapp"
    image     = var.ContainerImage
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

resource "aws_ecs_service" "chatapp" {
  name            = "chatapp"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.chatapp.arn
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = var.ec2TargetGroupARN
    container_name   = "chatapp"
    container_port   = 3000
  }
}


#https://aws.plainenglish.io/automating-deployment-of-a-node-js-application-on-amazon-ecs-using-aws-codepipeline-ef4d9a94c741