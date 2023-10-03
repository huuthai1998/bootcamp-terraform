resource "aws_codepipeline" "codepipeline-api" {
  name     = "api-bootcamp"
  role_arn = aws_iam_role.codepipeline_role_api.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket_api.bucket
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
        ProjectName = aws_codebuild_project.api.name
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket_api" {
  bucket = "pipeline-vtbxmck-api"
}

resource "aws_iam_role" "codepipeline_role_api" {
  name               = "codepipeline_role_api"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy_api" {
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
      aws_s3_bucket.codepipeline_bucket_api.arn,
      "${aws_s3_bucket.codepipeline_bucket_api.arn}/*"
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

resource "aws_iam_role_policy" "codepipeline_policy_api" {
  name   = "codepipeline_policy_api"
  role   = aws_iam_role.codepipeline_role_api.id
  policy = data.aws_iam_policy_document.codepipeline_policy_api.json
}

