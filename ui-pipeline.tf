resource "aws_codepipeline" "codepipeline-ui" {
  name     = "ui-bootcamp"
  role_arn = aws_iam_role.codepipeline_role_ui.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket_ui.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = 1
      output_artifacts = ["SOURCE_ARTIFACT"]
      configuration = {
        RepositoryName       = aws_codecommit_repository.bootcamp.repository_name
        BranchName           = "main"
        PollForSourceChanges = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SOURCE_ARTIFACT"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ui.name
      }
    }
  }
}


resource "aws_s3_bucket" "codepipeline_bucket_ui" {
  bucket = "pipeline-vtbxmck-ui"
}

data "aws_iam_policy_document" "assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role_ui" {
  name               = "codepipeline_role_ui"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy_ui" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket_ui.arn,
      "${aws_s3_bucket.codepipeline_bucket_ui.arn}/*"
    ]
  }

  statement {
    sid = "codecommitaccess"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy_ui" {
  name   = "codepipeline_policy_ui"
  role   = aws_iam_role.codepipeline_role_ui.id
  policy = data.aws_iam_policy_document.codepipeline_policy_ui.json
}

resource "aws_kms_key" "codepipeline" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
}
