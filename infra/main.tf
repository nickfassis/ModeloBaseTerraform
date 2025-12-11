resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
}

# Configure static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
    count  = var.enable_website_hosting ? 1 : 0
    bucket = aws_s3_bucket.bucket.id

    index_document {
        suffix = var.index_document
    }

    error_document {
        key = var.error_document
    }
}

# Public read policy for website objects
data "aws_iam_policy_document" "public_read" {
    count = var.enable_website_hosting ? 1 : 0

    statement {
        sid     = "PublicReadGetObject"
        effect  = "Allow"

        principals {
            type        = "AWS"
            identifiers = ["*"]
        }

        actions   = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.bucket.arn}/*"]
    }
}

resource "aws_s3_bucket_policy" "public" {
    count  = var.enable_website_hosting ? 1 : 0
    bucket = aws_s3_bucket.bucket.id
    policy = data.aws_iam_policy_document.public_read[0].json
}

# Upload all HTML files from ../app to the bucket
locals {
  app_html_files = fileset("../app", "**/*.html")
}

resource "aws_s3_object" "app_html" {
    for_each = var.enable_website_hosting ? { for f in local.app_html_files : f => f } : {}

    bucket       = aws_s3_bucket.bucket.id
    key          = basename(each.key)
    source       = "../app/${each.key}"
    content_type = "text/html"
    acl          = "public-read"
    etag         = filemd5("../app/${each.key}")

    depends_on = [aws_s3_bucket_policy.public]
}