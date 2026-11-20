data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.prefix}-s3-access"
  role   = var.role_id
  policy = data.aws_iam_policy_document.this.json
}
