resource "aws_s3_bucket" "bootcamp-codebuild" {
  force_destroy = true
  bucket        = "codebuild-log-vtb-bootcamp"
}

resource "aws_iam_role" "codebuild_api" {
  name               = "codebuild-api"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "EC2Container" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "EC2ContainerEks" {
  role       = aws_iam_role.codebuild_api.name
  policy_arn = data.aws_iam_policy.EC2Container.arn
}

data "aws_iam_policy_document" "codebuild_api" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.bootcamp-codebuild.arn,
      "${aws_s3_bucket.bootcamp-codebuild.arn}/*",
      aws_s3_bucket.codepipeline_bucket_api.arn,
      "${aws_s3_bucket.codepipeline_bucket_api.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_api" {
  role   = aws_iam_role.codebuild_api.name
  policy = data.aws_iam_policy_document.codebuild_api.json
}

resource "aws_codebuild_project" "api" {
  name          = "api-bootcamp"
  description   = "API Bootcamp project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_api.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.bootcamp-codebuild.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    privileged_mode = true

    environment_variable {
      name  = "ECR_IMAGE_NAME"
      value = "bootcamp-api"
    }

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.api.repository_url
    }
    environment_variable {
      name  = "EKS_ROLE_ARN"
      value = aws_iam_role.full_eks_permission_role.arn
    }
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = module.eks_cluster.eks_cluster_details.name
    }
    environment_variable {
      name  = "DEPLOYMENT_YML_FILE"
      value = "deployment.yaml"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.bootcamp-codebuild.id}/build-log"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/${aws_codecommit_repository.bootcamp.repository_name}"
    git_clone_depth = 1
    buildspec       = data.local_file.api_buildspec_local.content
    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "refs/heads/main"

  vpc_config {
    vpc_id = "vpc-0142ed266c5de6da2"

    subnets = [
      "subnet-04519d94985a172cc",
      "subnet-0368ee10ab9aa48f5",
    ]

    security_group_ids = [
      "sg-082cc0efcee8ad457"
    ]
  }

  tags = {
    Environment = "Test"
  }
}

data "local_file" "api_buildspec_local" {
  filename = "./api-buildspec.yml"
}
