variable "user_name" {
  type        = string
  description = "IAM user name"
}

variable "policy_name" {
  type        = string
  description = "IAM managed customer policy name (unique in account)"
}

variable "policy_document" {
  type        = string
  description = "IAM policy JSON document"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the IAM user and policy"
  default     = {}
}
