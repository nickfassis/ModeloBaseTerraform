resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
}

# CORS to allow your domain to access S3 website
resource "aws_s3_bucket_cors_configuration" "cors" {
    count  = var.cors_allowed_origin != null ? 1 : 0
    bucket = aws_s3_bucket.bucket.id

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = [var.cors_allowed_origin]
        expose_headers  = ["ETag"]
        max_age_seconds = 300
    }
}

# Allow public policy attachment for website hosting
resource "aws_s3_bucket_public_access_block" "this" {
    count  = var.enable_website_hosting ? 1 : 0
    bucket = aws_s3_bucket.bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
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
    depends_on = [aws_s3_bucket_public_access_block.this]
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
    etag         = filemd5("../app/${each.key}")

    depends_on = [aws_s3_bucket_policy.public, aws_s3_bucket_cors_configuration.cors]
}