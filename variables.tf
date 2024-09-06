variable "signed_url_bucket_names" {
  description = "signedurl bucket names"
  type        = list(string)
  default     = ["test01", "test02"]
}

variable "bucket_list" {
  description = "cloudfront connect bucket names"
  type        = list(string)
  default     = ["test01", "test02"]
}

variable "csp" {
  description = "csp name"
  type        = string
  default     = "aws"
}

variable "env" {
  description = "environment type"
  type        = string
  default     = "test"
}

variable "region" {
  description = "region name"
  type        = string
  default     = "an2"
}
variable "region_raw" {
  description = "map your region to full region name"
  type        = map(string)
  default     = { an2 = "ap-northeast-2" }
}

variable "domain_name" {
  description = "surl default domain name"
  type        = string
  default     = "https://www.test.com"
}

variable "exp_time" {
  description = "expire minute for surl"
  type        = number
  default     = 10
}

variable "secret_name" {
  description = "secrets manager secret name for surl"
  type        = string
  default     = "test/surl"
}

