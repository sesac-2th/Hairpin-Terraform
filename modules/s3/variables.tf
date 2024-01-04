data "aws_cloudfront_distribution" "cloudfront" {
  id = "EI0QXNBFCNPWW"
}
data "aws_iam_policy_document" "PolicyForCloudFrontPrivateContent" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    sid = "AllowCloudFrontServicePrincipal"

    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        data.aws_cloudfront_distribution.cloudfront.arn
      ]
    }
  }
}

variable "bucket_name" {
  type = string
}

variable "rule" {

}
