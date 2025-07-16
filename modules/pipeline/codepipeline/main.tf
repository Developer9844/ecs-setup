resource "aws_iam_role" "codepipeline_role" {
  name = "ecsCodePipelineRole"

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

# resource "aws_iam_policy" "codepipeline_custom" {
#   name = "codepipelineCustom"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#         Effect = "Allow",
#         Action = [
#             "ecr:DescribeImages"
#         ],
#         Resource = "*"
#     }]
#   })
# }


# resource "aws_iam_role_policy_attachment" "codepipeline_custome_policy_attach" {
#   role       = aws_iam_role.codepipeline_role.name
#   policy_arn = aws_iam_policy.codepipeline_custom.arn
# }


resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "chatapp-artifacts-${random_id.suffix.hex}"
  force_destroy = true
}




resource "aws_codestarconnections_connection" "github_connection" {
  name          = "github-connection-chatapp"
  provider_type = "GitHub"
}







resource "aws_codepipeline" "chatapp_pipeline" {
  name     = "chatapp-frontend"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github_connection.arn
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
