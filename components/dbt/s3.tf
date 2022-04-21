resource "aws_s3_bucket" "this" {
  bucket = module.dbt_labels.id
  tags   = module.dbt_labels.tags
}

resource "aws_s3_object" "this" {
  for_each = fileset(var.project_dir, "**/*")
  bucket   = aws_s3_bucket.this.bucket
  key      = "${var.dbt_dir}/${each.value}"
  source   = "${var.project_dir}/${each.value}"
  etag     = filemd5("${var.project_dir}/${each.value}")
}

resource "aws_iam_role" "s3-access" {
  name               = "${module.dbt_labels.id}-sync"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.s3-access.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_policy" "policy" {
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = ""
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}