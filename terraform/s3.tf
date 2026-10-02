resource "aws_s3_bucket" "immutable" {
  bucket              = var.bucket_name
  object_lock_enabled = true # can only be set at creation time
}

resource "aws_s3_bucket_versioning" "immutable" {
  bucket = aws_s3_bucket.immutable.id
  versioning_configuration {
    status = "Enabled" # required for Object Lock
  }
}

resource "aws_s3_bucket_object_lock_configuration" "immutable" {
  bucket     = aws_s3_bucket.immutable.id
  depends_on = [aws_s3_bucket_versioning.immutable]

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "immutable" {
  bucket = aws_s3_bucket.immutable.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.vault.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "immutable" {
  bucket                  = aws_s3_bucket.immutable.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "immutable" {
  bucket = aws_s3_bucket.immutable.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# TLS-only access and no unencrypted uploads.
data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.immutable.arn, "${aws_s3_bucket.immutable.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyWrongKmsKey"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.immutable.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.vault.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "immutable" {
  bucket = aws_s3_bucket.immutable.id
  policy = data.aws_iam_policy_document.bucket.json
}
