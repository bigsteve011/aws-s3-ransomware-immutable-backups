# Logically air-gapped backups: vaults are locked in compliance mode, so recovery points
# cannot be deleted or have retention shortened, even by an administrator.
resource "aws_backup_vault" "primary" {
  name        = "immutable-primary"
  kms_key_arn = aws_kms_key.vault.arn
}

resource "aws_backup_vault_lock_configuration" "primary" {
  backup_vault_name   = aws_backup_vault.primary.name
  min_retention_days  = var.retention_days
  max_retention_days  = 365
  changeable_for_days = 3 # grace period; after this the lock is permanent
}

resource "aws_backup_vault" "dr" {
  provider    = aws.dr
  name        = "immutable-dr"
  kms_key_arn = aws_kms_key.vault_dr.arn
}

resource "aws_backup_vault_lock_configuration" "dr" {
  provider            = aws.dr
  backup_vault_name   = aws_backup_vault.dr.name
  min_retention_days  = var.retention_days
  max_retention_days  = 365
  changeable_for_days = 3
}

resource "aws_backup_plan" "daily" {
  name = "daily-immutable"

  rule {
    rule_name         = "daily-0300-utc"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = var.retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn
      lifecycle {
        delete_after = var.retention_days
      }
    }
  }
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "aws-backup-immutable"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "s3_backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

# Back up every resource tagged backup=immutable.
resource "aws_backup_selection" "tagged" {
  name         = "tag-backup-immutable"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "immutable"
  }
}
