resource "aws_ecs_cluster" "this" {
  name = module.dbt_labels.id
  tags = module.dbt_labels.tags
}
# ECS
module "dbt_ecs" {
  source = "github.com/cloudposse/terraform-aws-ecs-container-definition?ref=0.57.0"
  # version = "0.57.0"
  container_name   = "${module.dbt_labels.id}-executor"
  container_image  = "public.ecr.aws/v6j5p4v4/kozmischeheide/dbt"
  container_memory = 2048
  essential        = true

  command = ["compile", "--profiles-dir", "/usr/app/"]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = var.region
      awslogs-group         = aws_cloudwatch_log_group.logs.name
      awslogs-stream-prefix = aws_cloudwatch_log_stream.log_stream.name
      awslogs-stream-prefix = "ecs"
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  task_role_arn = aws_iam_role.s3-access.arn
  family                   = module.dbt_labels.id
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = "[${module.dbt_ecs.json_map_encoded}]"
  execution_role_arn       = aws_iam_role.execution.arn
  volume {
    name = module.dbt_labels.id
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      root_directory          = "/usr/app/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.test.id
        iam             = "ENABLED"
      }
    }

  }
  tags                     = module.dbt_labels.tags
}

resource "aws_ecs_service" "this" {
  name             = module.dbt_labels.id
  cluster          = aws_ecs_cluster.this.name
  launch_type      = "FARGATE"
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = 0
  platform_version = "1.4.0"

  network_configuration {
    security_groups = [aws_security_group.efs.id]
    subnets = var.subnets
  }
  tags = module.dbt_labels.tags
}

# IAM
data "aws_iam_policy_document" "service" {
  statement {
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid    = "allowCloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "${module.dbt_labels.id}-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

resource "aws_iam_role" "execution" {
  name               = "${module.dbt_labels.id}-execution"
  assume_role_policy = data.aws_iam_policy_document.service.json
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${module.dbt_labels.id}"
  retention_in_days = 14
  tags              = module.dbt_labels.tags
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  log_group_name = aws_cloudwatch_log_group.logs.name
  name           = module.dbt_labels.id
}

# SG
resource "aws_security_group" "efs" {
  name_prefix = "test-ecs"
  description = "Allow strict inbound access to ECS Tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}