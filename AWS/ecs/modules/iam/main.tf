resource "aws_iam_user" "main" {
  name = var.user_name
  path = "/"

  tags = var.tags
}

resource "aws_iam_policy" "main" {
  name        = var.policy_name
  description = "Policy attached to ${var.user_name}"
  policy      = var.policy_document

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "main" {
  user       = aws_iam_user.main.name
  policy_arn = aws_iam_policy.main.arn
}
