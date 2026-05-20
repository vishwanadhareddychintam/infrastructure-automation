locals {
  execution_role_name = substr(replace("${var.cluster_name}-ecs-exec", "/", "-"), 0, 64)
}

resource "aws_iam_role" "ecs_execution" {
  name = local.execution_role_name

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

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Pull Secrets Manager / SSM secrets referenced in task definition secret ARNs at deploy time.
data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    sid = "SecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*",
    ]
  }

  statement {
    sid = "SsmParameters"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/*",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name   = "ECSTaskExecutionSecrets"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}
