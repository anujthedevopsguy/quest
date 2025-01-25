# Setup repo in the ECR
resource "aws_ecr_repository" "quest" {
  name = "quest"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "quest_codebuild_role" {
  name = "quest-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for CodeBuild Role
resource "aws_iam_policy" "codebuild_policy" {
  name        = "quest-iam-policy"
  description = "IAM policy to access ECR, S3, and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to the Role
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.quest_codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# Create a CodeBuild Project
resource "aws_codebuild_project" "nodejs_build" {
  name           = "quest-codebuild"
  description    = "Builds a Node.js Docker image and pushes it to ECR"
  service_role   = aws_iam_role.quest_codebuild_role.arn
  source_version = "main"
  source {
    type            = "GITHUB"
    location        = "https://github.com/anujthedevopsguy/quest.git"
    git_clone_depth = 1
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0" 
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable     {
            name  = "REPO_NAME"
            value = aws_ecr_repository.quest.name
        }
    environment_variable {
            name  = "REPO_URI"
            value = aws_ecr_repository.quest.repository_url
        }
    environment_variable {
          name  = "ACCOUNT_ID"
          value = data.aws_caller_identity.current.account_id
      }
    environment_variable {
          name  = "REGION"
          value = var.region
      }
    }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/quest-build"
      stream_name = "build-log"
    }
  }
}

