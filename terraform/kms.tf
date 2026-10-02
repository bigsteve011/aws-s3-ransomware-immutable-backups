data "aws_caller_identity" "current" {}

# Key policy: administration is limited to named roles; S3 and Backup may use the key
# only on behalf of this account. Deleting the key needs the 30-day waiting period.
data "aws_iam_policy_document" "cmk" {
  statement {
    sid       = "AccountRootCanDelegateViaIam"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "KeyAdministrators"
    actions = [
      "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*",
      "kms:Update*", "kms:Revoke*", "kms:Get*", "kms:TagResource", "kms:UntagResource",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = var.backup_admin_role_arns
    }
  }

  statement {
    sid       = "DenyKeyDeletionOutsideAdmins"
    effect    = "Deny"
    actions   = ["kms:ScheduleKeyDeletion", "kms:DisableKey"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = var.backup_admin_role_arns
    }
  }
}

resource "aws_kms_key" "vault" {
  description             = "CMK for immutable records and backups"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.cmk.json
}

resource "aws_kms_alias" "vault" {
  name          = "alias/immutable-vault"
  target_key_id = aws_kms_key.vault.key_id
}

resource "aws_kms_key" "vault_dr" {
  provider                = aws.dr
  description             = "CMK for cross-region backup copies"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.cmk.json
}
