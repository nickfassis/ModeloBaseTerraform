variable "bucket_name" {
    type = string
}

variable "enable_website_hosting" {
    type        = bool
    description = "Enable static website hosting on the S3 bucket"
    default     = true
}

variable "index_document" {
    type        = string
    description = "Index document for S3 static website"
    default     = "index.html"
}

variable "error_document" {
    type        = string
    description = "Error document for S3 static website"
    default     = "error.html"
}

variable "allowed_origin" {
    type        = string
    description = "Hostname que poderá acessar via CDN/CloudFront (ex.: dev.faveni.ministrare.work)"
    default     = null
}