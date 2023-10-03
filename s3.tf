resource "aws_s3_bucket" "example" {
  bucket = "vtbxmck-bootcamp-ui"
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

output "website_url" {
  value = "http://${aws_s3_bucket.example.bucket}.s3-website.us-east-1.amazonaws.com"
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.example.id

  policy     = <<POLICY
{
  "Id": "Policy",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.example.bucket}/*",
      "Principal": {
        "AWS": [
          "*"
        ]
      }
    }, 
      {
            "Sid": "Stmt1597860486271",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.codebuild_ui.arn}"
            },
            "Action": "*",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.example.bucket}/*"
        }
  ]
}
POLICY
  depends_on = [aws_s3_bucket.example]
}
