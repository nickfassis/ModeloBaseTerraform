output "website_endpoint" {
  description = "Endpoint público do site estático do S3"
  value       = var.enable_website_hosting ? aws_s3_bucket_website_configuration.website[0].website_endpoint : null
}

output "website_domain" {
  description = "Domínio do site estático do S3"
  value       = var.enable_website_hosting ? aws_s3_bucket_website_configuration.website[0].website_domain : null
}