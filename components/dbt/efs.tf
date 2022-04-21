resource "aws_efs_file_system" "this" {
  creation_token = module.dbt_labels.id
  tags           = module.dbt_labels.tags
}

resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.this.id
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.subnets)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}


resource "aws_datasync_location_s3" "s3" {
  s3_bucket_arn = aws_s3_bucket.this.arn
  subdirectory  = "projects/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.s3-access.arn
  }
}

resource "aws_datasync_location_efs" "efs" {
  # The below example uses aws_efs_mount_target as a reference to ensure a mount target already exists when resource creation occurs.
  # You can accomplish the same behavior with depends_on or an aws_efs_mount_target data source reference.
  efs_file_system_arn = aws_efs_mount_target.this[0].file_system_arn

  ec2_config {
    security_group_arns = [aws_security_group.efs.arn]
    subnet_arn          = var.subnet_arns[0]
  }
}

resource "aws_datasync_task" "this" {
  destination_location_arn = aws_datasync_location_efs.efs.arn
  name                     = "test-sync"
  source_location_arn      = aws_datasync_location_s3.s3.arn

  options {
    bytes_per_second = -1
  }
}