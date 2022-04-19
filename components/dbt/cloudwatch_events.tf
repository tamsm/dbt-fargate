resource "aws_cloudwatch_event_rule" "this" {
  for_each            = {for i, v in var.executions : i=>v}
  name                = "${module.dbt_labels.id}-${each.value.process}"
  schedule_expression = each.value.schedule
}

resource "aws_cloudwatch_event_target" "this" {
  for_each  = {for i, v in var.executions : i=>v}
  target_id = "${module.dbt_labels.id}-${each.value.process}"
  arn       = aws_ecs_cluster.this.arn
  rule      = aws_cloudwatch_event_rule.this[each.key].name
  role_arn  = aws_iam_role.execution.arn
  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.this.arn
  }
  input     = jsonencode(
  {
    containerOverrides = [
      {
        name    = module.dbt_labels.id,
        command = each.value.command
      }
    ]
  })

}