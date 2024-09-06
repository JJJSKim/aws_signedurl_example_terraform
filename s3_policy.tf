# Bucket에 Cloudfront OAC 접근 허용
resource "aws_s3_bucket_policy" "allow_oac" {
  for_each = toset(var.bucket_list)
  bucket   = aws_s3_bucket.b[each.value].id
  policy   = data.aws_iam_policy_document.allow_oac[each.value].json
}

# aws_s3_bucket_policy 에서 사용할 권한 정의
data "aws_iam_policy_document" "allow_oac" {
  for_each = toset(var.bucket_list)
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.b[each.value].arn,
      "${aws_s3_bucket.b[each.value].arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.s3_distribution.arn}"]
    }
  }
}