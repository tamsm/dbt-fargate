resource "aws_ecs_cluster" "this" {
  name = module.dbt_labels.id
  tags = module.dbt_labels.tags
}

module "dbt_ecs" {
  source = "github.com/cloudposse/terraform-aws-ecs-container-definition?ref=0.57.0"
  # version = "0.57.0"
  container_name   = "${module.dbt_labels.id}-executor"
  container_image  = "public.ecr.aws/amazonlinux/amazonlinux:2"
  container_memory = 100
  essential        = true

  entrypoint = ["/usr/bin/env", "bash", "-c"]
  command = [<<EOT
for file in ${var.project_dir}/*
do
  echo $file
  cat $file
done
EOT
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = var.region
      awslogs-group         = module.dbt_labels.id
      awslogs-stream-prefix = "ecs"
      awslogs-create-group  = true
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = module.dbt_labels.id
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
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