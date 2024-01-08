resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

# ==== 버킷 권한 설정 ====
resource "aws_s3_bucket_ownership_controls" "s3_ownership_control" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = var.rule
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.PolicyForCloudFrontPrivateContent.json
}

# resource "aws_s3_bucket_public_access_block" "example" {
#   bucket = aws_s3_bucket.example.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# resource "aws_s3_bucket_acl" "s3_acl" {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.s3_ownership_control
#   ]

#   bucket = aws_s3_bucket.example.id
#   acl    = "public-read"
# }

