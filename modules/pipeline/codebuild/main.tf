resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

locals {
  connection_id = split("/", data.aws_codestarconnections_connection.github.arn)[1]
}

resource "aws_iam_role_policy" "allow_custom_policies" {
  name = "AllowCustomPoliciesToCodePipeline"
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
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
            "codeconnections:UseConnection"
        ],
        Resource = [
            "arn:aws:codestar-connections:${var.aws_region}:${var.account_id}:connection/${local.connection_id}",
            "${data.aws_codestarconnections_connection.github.arn}"
        ]
        }
      
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}





data "aws_codestarconnections_connection" "github" {
  name = "my-github-connection"
}

resource "aws_codebuild_project" "frontendCodeBuildProject" {
  name          = "frontend-build"
  description   = "Builds project from GitHub"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/Developer9844/auth_app.git"
    git_clone_depth = 1
    buildspec = "buildspec-frontend.yaml"
    auth {
      type = "CODECONNECTIONS"
      resource = data.aws_codestarconnections_connection.github.arn
    }
  }
  source_version = "master"  
}



resource "aws_codebuild_project" "backendCodeBuildProject" {
  name          = "backend-build"
  description   = "Builds project from GitHub"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/Developer9844/auth_app.git"
    git_clone_depth = 1
    buildspec = "buildspec-backend.yaml"
    auth {
      type = "CODECONNECTIONS"
      resource = data.aws_codestarconnections_connection.github.arn
    }
  }

  source_version = "master"
}