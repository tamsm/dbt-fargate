resource "aws_ecs_cluster" "this" {
  name = module.dbt_labels.id
  tags = module.dbt_labels.tags
}

module "dbt_ecs" {
  source = "github.com/cloudposse/terraform-aws-ecs-container-definition?ref=0.57.0"
  # version = "0.57.0"
  container_name   = "${module.dbt_labels.id}-executor"
  container_image  = "public.ecr.aws/v6j5p4v4/kozmischeheide/dbt"
  container_memory = 100
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
  family                   = module.dbt_labels.id
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions    = "[${module.dbt_ecs.json_map_encoded}]"
  execution_role_arn       = aws_iam_role.execution.arn
  volume {
    name = module.dbt_labels.id
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
    subnets = var.subnets
  }
  tags = module.dbt_labels.tags
}


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