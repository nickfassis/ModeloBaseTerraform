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

variable "cors_allowed_origin" {
    type        = string
    description = "Origin (scheme + host) allowed by S3 CORS, e.g. http://dev.faveni.ministrare.work"
    default     = null
}