# S3 사용 로컬 변수
locals {
  s3_prefix = join("-", [
    local.resource_prefix,
    "s3"
  ])
}

# bucket_list에 따른 bucket 생성
resource "aws_s3_bucket" "b" {
  for_each = toset(var.bucket_list)
  bucket   = join("-", [local.s3_prefix, each.value, local.resource_suffix])

  tags = {
    Name      = join("-", [local.s3_prefix, each.value, local.resource_suffix])
    terraform = "true"
  }
}

# bucket ownership control 변경
resource "aws_s3_bucket_ownership_controls" "b_own" {
  for_each = toset(var.bucket_list)
  bucket   = aws_s3_bucket.b[each.value].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

}

# bucket ownership control 변경이 버킷에 반영될 시간 대기
# 만약 해당 섹션에서 오류 발생 시 다시 한 번 Apply 진행
resource "time_sleep" "bucket_ownership_wait" {
  depends_on      = [aws_s3_bucket_ownership_controls.b_own]
  create_duration = "20s"
}

# bucket acl을 private로 설정
resource "aws_s3_bucket_acl" "b_acl" {
  for_each   = toset(var.bucket_list)
  bucket     = aws_s3_bucket.b[each.value].id
  acl        = "private"
  depends_on = [time_sleep.bucket_ownership_wait]
}
