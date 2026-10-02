# Ransomware-Proofing AWS Data: Immutable S3 Object Lock, KMS Customer Managed Keys & Air-Gapped Backups

> Architecting write-once-read-many (WORM) immutable data storage using S3 Object Lock in Compliance mode, Customer Managed Keys (CMKs) with envelope encryption, and air-gapped AWS Backup vaults with cross-region replication.

Companion repository for the article **[Ransomware-Proofing AWS Data: Immutable S3 Object Lock, KMS Customer Managed Keys & Air-Gapped Backups](https://stephen-omowumi.pages.dev/articles/aws-s3-ransomware-object-lock)** by Stephen Omowumi.

## The problem

Sophisticated ransomware operators compromise cloud IAM admin credentials to delete snapshots, overwrite backups, and delete S3 version histories prior to initiating encryption payloads.

## Solution architecture

Implement S3 Object Lock in Compliance mode with a 90-day retention lock (preventing deletion even by the AWS root account). Utilize dual-region KMS encryption with separated key administrator vs. key user roles. Replicate backups to a physically separate AWS account with an isolated VPC.

## How it works

1. **S3 Bucket Initialization with Object Lock** — Create S3 bucket with Object Lock enabled at creation; set default retention in Compliance Mode.
2. **Role-Segregated KMS Key Management** — Key policy allows key rotation and usage only by designated backup services; denies root deletion.
3. **Cross-Account AWS Backup Vault Lock** — Replicate snapshots to a secondary AWS Disaster Recovery Account with Vault Lock in Governance/Compliance.
4. **Automated Recovery Drill Orchestration** — Quarterly automated restore testing validating RTO < 2 hours and RPO < 15 minutes.

## Repository layout

```
terraform/
  kms.tf      rotating customer managed keys; deletion/disable restricted to break-glass roles
  s3.tf       Object Lock (COMPLIANCE mode), versioning, CMK encryption, TLS-only, public access blocked
  backup.tf   AWS Backup vaults with Vault Lock, daily plan, cross-region copy
              (for a cross-account copy, point copy_action at a locked vault in your DR account)
```

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform plan
```
> **Warning:** COMPLIANCE-mode Object Lock and Vault Lock are irreversible by design. Objects cannot be deleted before their retention date, even by the root user, and a locked vault cannot be unlocked after `changeable_for_days`. Use short retention in test accounts.

## Outcomes (as described in the article)

| Measure | Result |
|---|---|
| Data Immutability | WORM Compliant |
| Recovery Time (RTO) | < 2 Hours |
| Ransomware Resilience | 100% Tested |

## Key takeaways

- Compliance Mode guarantees mathematical data immutability against insider threat and ransomware
- Cross-account backup vault ensures business continuity even in total primary account compromise
- Satisfies stringent European DORA and SEC Rule 17a-4 electronic record preservation mandates

## Notes

This is a reference implementation. Names, account IDs, regions and allow-lists are placeholders: review and adapt them, and test in a non-production environment before rolling out.

## License

MIT — see [LICENSE](LICENSE).
