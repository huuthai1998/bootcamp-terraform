resource "aws_s3_bucket" "bootcamp-codebuild--ui" {
  force_destroy = true
  bucket        = "codebuild-log-vtb-bootcamp-ui"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_ui" {
  name               = "codebuild-ui"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codebuild_ui" {
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
      "codecommit:GitPull",
    ]

    resources = [aws_codecommit_repository.bootcamp.arn]
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
      aws_s3_bucket.codepipeline_bucket_ui.arn,
      "${aws_s3_bucket.codepipeline_bucket_ui.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_ui" {
  role   = aws_iam_role.codebuild_ui.name
  policy = data.aws_iam_policy_document.codebuild_ui.json
}

resource "aws_codebuild_project" "ui" {
  name          = "ui-bootcamp"
  description   = "ui Bootcamp project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_ui.arn

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

    environment_variable {
      name  = "S3_BUCKET_UI"
      value = aws_s3_bucket.example.bucket
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
    buildspec       = data.local_file.ui_buildspec_local.content
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

data "local_file" "ui_buildspec_local" {
  filename = "./ui-buildspec.yml"
}
