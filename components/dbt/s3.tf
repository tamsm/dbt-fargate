resource "aws_s3_bucket" "this" {
  bucket = module.dbt_labels.id
  tags   = module.dbt_labels.tags
}

resource "aws_s3_bucket_object" "this" {
  for_each = fileset(var.project_dir, "**/*")
  bucket   = aws_s3_bucket.this.bucket
  key      = each.value
  source   = "${var.project_dir}/${each.value}"
  etag     = filemd5("${var.project_dir}/${each.value}")
}
