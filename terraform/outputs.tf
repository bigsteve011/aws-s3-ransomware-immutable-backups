output "bucket" {
  value = aws_s3_bucket.immutable.id
}

output "kms_key_arn" {
  value = aws_kms_key.vault.arn
}

output "backup_vaults" {
  value = [aws_backup_vault.primary.arn, aws_backup_vault.dr.arn]
}
