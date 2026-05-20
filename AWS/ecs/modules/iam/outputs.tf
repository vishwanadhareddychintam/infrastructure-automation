output "user_name" {
  value = aws_iam_user.main.name
}

output "user_arn" {
  value = aws_iam_user.main.arn
}

output "policy_arn" {
  value = aws_iam_policy.main.arn
}

output "policy_id" {
  value = aws_iam_policy.main.id
}
