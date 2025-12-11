resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
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

        depends_on = [aws_s3_bucket_policy.public]
}

# CloudFront distribution in front of S3 website endpoint (HTTPS to users)
resource "aws_cloudfront_distribution" "s3_website" {
    count               = var.enable_website_hosting ? 1 : 0
    enabled             = true
    default_root_object = var.index_document

    origin {
        domain_name = aws_s3_bucket_website_configuration.website[0].website_domain
        origin_id   = "s3-website-origin"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "http-only" # S3 website endpoint supports HTTP
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    default_cache_behavior {
        target_origin_id       = "s3-website-origin"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
        minimum_protocol_version       = "TLSv1.2_2021"
    }

    # Optional logging/aliases could be added when ACM cert exists
}