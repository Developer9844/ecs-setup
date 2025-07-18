resource "aws_iam_role" "codepipeline_role" {
  name = "My-CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy" "codepipeline_custom" {
  name = "codepipelineCustom"
  role = aws_iam_role.codepipeline_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ],
        Resource = [
          "arn:aws:codestar-connections:${var.aws_region}:${var.account_id}:connection/${local.connection_id}",
          "${data.aws_codestarconnections_connection.github.arn}"
        ]
      },
      {
        "Sid" : "TaskDefinitionPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Sid" : "ECSServicePermissions",
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        "Resource" : [
          "arn:aws:ecs:*:600748199510:service/My-Cluster/*"
        ]
      },
      {
        "Sid" : "ECSTagResource",
        "Effect" : "Allow",
        "Action" : [
          "ecs:TagResource"
        ],
        "Resource" : [
          "arn:aws:ecs:*:600748199510:task-definition/arn:aws:ecs:us-east-1:600748199510:task-definition/fargateTaskDefination:6:*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ecs:CreateAction" : [
              "RegisterTaskDefinition"
            ]
          }
        }
      },
      {
        "Sid" : "IamPassRolePermissions",
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : [
          "arn:aws:iam::600748199510:role/My-Cluster-ecsTaskExecutionRole"
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : [
              "ecs.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}


data "aws_codestarconnections_connection" "github" {
  name = "my-github-connection"
}
locals {
  connection_id = split("/", data.aws_codestarconnections_connection.github.arn)[1]
}


resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-artifacts-bucket-3924"
}


resource "aws_codepipeline" "chatapp_pipeline" {
  name     = "chatapp-frontend"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = "codepipeline-artifacts-bucket-3924"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = "Developer9844/auth_app"
        BranchName       = "master"
        DetectChanges    = "true"
      }

      run_order = 1
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "frontend-build"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ECS_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = "My-Cluster"
        ServiceName = "fargateService"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
