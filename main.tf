provider "aws" {
  region = "eu-west-2"
}

# Create S3 bucket for static website
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "aws-mystaticwebsite-abdullah3"
}

# Create server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "static_website_encryption" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Create website configuration for the S3 bucket
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "static_website_bucket_public_access_block" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false  # Ensure this is set to false
  restrict_public_buckets = false
}


# Get all HTML files in the same folder as main.tf
data "local_file" "website_files" {
  for_each = fileset("${path.module}", "*.html")
  filename = "${path.module}/${each.value}"
}

# Upload each HTML file to the S3 bucket
resource "aws_s3_object" "website_files" {
  for_each = data.local_file.website_files

  bucket       = aws_s3_bucket.static_website_bucket.bucket
  key          = each.key
  source       = each.value.filename
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.static_website_bucket.bucket
  depends_on = [aws_s3_bucket_public_access_block.static_website_bucket_public_access_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.static_website_bucket.bucket}/*"
        Principal = "*"
      }
    ]
  })
}