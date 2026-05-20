locals {
  task_role_name = substr(replace("${var.cluster_name}-ecs-task", "/", "-"), 0, 64)
}

resource "aws_iam_role" "ecs_task" {
  name = local.task_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Runtime permissions for application code (not the ECS agent / secret injection).
data "aws_iam_policy_document" "ecs_task_runtime" {
  statement {
    sid = "SesSend"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["*"]
  }

  statement {
    sid = "BedrockInvoke"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:ListFoundationModels",
      "bedrock:GetFoundationModel",
    ]
    resources = ["*"]
  }

  # IAM DB authentication for RDS / Aurora (narrow dbuser ARNs in AWS when you know instance + db user names).
  statement {
    sid = "RdsIamDbAuth"
    actions = [
      "rds-db:connect",
    ]
    resources = [
      "arn:aws:rds-db:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:dbuser:*/*",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_runtime" {
  name   = "EcsTaskRuntime"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_runtime.json
}
