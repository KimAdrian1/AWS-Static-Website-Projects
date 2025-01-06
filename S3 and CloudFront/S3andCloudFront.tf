provider "aws" {
  region     = ""
  access_key = ""
  secret_key = ""
}

# Gives Terraform information about our account which would be used later
data "aws_caller_identity" "current" {}

# Creates the bucket to host the files for the static website
resource "aws_s3_bucket" "bucketForWebsiteHosting" {
  bucket = "movie-project-thingy-terraform"

}

# Referencing the bucket policy to give the cloudfront OAC access to the bucket
resource "aws_s3_bucket_policy" "bucketPolicy" {
  bucket     = aws_s3_bucket.bucketForWebsiteHosting.id
  policy     = data.aws_iam_policy_document.oacPolicyDocument.json
  depends_on = [aws_cloudfront_distribution.cloudfrontDistribution]
}

# Creates the OAC for the CloudFront Distribution
resource "aws_cloudfront_origin_access_control" "cloudfrontOriginAccessControl" {
  name                              = "s3-0AC"
  description                       = "OAC for secure access to the S3 bucket: movie-project-thingy-terraform"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Creates the CloudFront distribution that would serve the webiste from the bucket to the end users
resource "aws_cloudfront_distribution" "cloudfrontDistribution" {
  enabled = true
  origin {
    domain_name              = aws_s3_bucket.bucketForWebsiteHosting.bucket_domain_name
    origin_id                = "s3origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfrontOriginAccessControl.id
  }
  default_cache_behavior {
    target_origin_id       = "s3origin"
    viewer_protocol_policy = "redirect-to-https" # Main reason we are using a CloudFront Distribution to serve the S3 website is to get HTTPS
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
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
    cloudfront_default_certificate = "true"
  }
  default_root_object = "grid.html"
}

# This is the written bucket policy that is referenced in the resource "bucketPolicy"
data "aws_iam_policy_document" "oacPolicyDocument" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = ["${aws_s3_bucket.bucketForWebsiteHosting.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cloudfrontDistribution.id}"]

    }
  }
}

# Gives Terraform the URL of the CloudFront Distribution
output "cloudfrontDistributionDomainName" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cloudfrontDistribution.domain_name
}
