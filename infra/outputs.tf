output "website_endpoint" {
  description = "Endpoint público do site estático do S3"
  value       = var.enable_website_hosting ? aws_s3_bucket_website_configuration.website[0].website_endpoint : null
}

output "website_domain" {
  description = "Domínio do site estático do S3"
  value       = var.enable_website_hosting ? aws_s3_bucket_website_configuration.website[0].website_domain : null
}

output "cloudfront_domain_name" {
  description = "Domínio da distribuição CloudFront"
  value       = var.enable_website_hosting ? aws_cloudfront_distribution.s3_website[0].domain_name : null
}

output "cloudfront_url" {
  description = "URL de acesso via CloudFront (HTTPS)"
  value       = var.enable_website_hosting ? "https://${aws_cloudfront_distribution.s3_website[0].domain_name}" : null
}