# DNS infrastructure

Terraform manages Route 53 records for robw.fyi and flakery.xyz, plus the existing
robw.fyi certificate and CloudFront redirect. Routine DNS updates use only AWS.
Namecheap delegation is isolated in the optional `registrar/` stack and is never
run by GitHub Actions.

## GitHub Actions

Pull requests and pushes to `main` run formatting, validation, and the DNS plan
boundary tests without AWS access. To update DNS:

1. Edit the DNS records and merge the reviewed changes to `main`.
2. Open Actions → Manage DNS → Run workflow, select `main`, and choose `plan`.
3. Review the Terraform plan in the run logs.
4. Run again with `apply` to create, check, and apply a fresh saved plan.

Only the `main` branch can assume the `github-dns` OIDC role. No AWS keys are
stored in GitHub. The role can change supported record types in just the two
existing hosted zones. It cannot change NS/SOA records, create or delete zones,
modify Namecheap, or change CloudFront or ACM. Existing CloudFront and certificate
resources are readable for Terraform refresh. The plan check also rejects
non-DNS changes. Plans and state are not uploaded as GitHub artifacts.

Apply is manual; it does not automatically deploy on merge. The second run
creates a fresh plan, so review its logs too. For changes outside DNS records,
use separately authorized administrative credentials and review the plan locally.
Protect `main` with review requirements appropriate to your collaborators;
anyone able to change workflows on `main` can exercise this role's DNS permissions.

## State and AWS setup

Terraform >= 1.10 is required; workflows use 1.13.5. The S3 backend uses encryption,
versioning, public-access blocking, and native state locking. State is private at
`s3://r33drichards-dns-tfstate-390825964154/dns/terraform.tfstate`.

The reviewed policies are in `iam/`. `scripts/bootstrap_aws.py` creates the
bucket, `github-dns` role, and `dns-local` user using administrative credentials.
It refuses to overwrite existing identities or an existing bucket. The local
user has the same scoped policy and initially has no console login or access
keys. Configure its authentication separately if local access is wanted.

Before the first workflow, migrate the existing local state into the private
backend. Preserve a secure backup and detach only these registrar resources:

```sh
terraform state rm -dry-run \
  'module.robw_fyi_dns.namecheap_domain_records.domain' \
  'module.flakery_xyz_dns.namecheap_domain_records.domain'
```

Do not simply run init against an empty backend and apply: the infrastructure
already exists. A migration copy must retain all AWS resources and state lineage,
remove only the two Namecheap resources, and include the delegation output.
After verifying the copied state, initialize against S3 and review a plan.
Never apply an unexpected recreation or deletion. Keep the original local state
as a secure backup until remote-state verification completes.

## Local DNS updates

Use AWS environment credentials, a configured AWS profile, or temporary session
credentials. The provider uses the AWS credential chain by default. Legacy
`aws_access_key` / `aws_secret_key` variables remain optional for the existing
local configuration; prefer the credential chain so the backend uses the same
identity. Root `terraform.tfvars` is ignored and never needed by Actions.

```sh
terraform init
terraform validate
terraform plan -out=dns.tfplan
terraform show -json dns.tfplan > dns-plan.json
python3 scripts/check_dns_plan.py dns-plan.json
terraform apply dns.tfplan
```

## Optional Namecheap delegation

The existing registrar nameservers remain unchanged by the state migration.
You can manage them manually using `terraform output delegation_nameservers`.
For Terraform management, copy `registrar/terraform.tfvars.example` to
`registrar/terraform.tfvars`, supply a rotated Namecheap API key, and use an
allowlisted source IP. The registrar stack reads the root S3 state and keeps
its own local state, which must also be backed up securely.

```sh
terraform -chdir=registrar init
terraform -chdir=registrar import 'namecheap_domain_records.domain["robw.fyi"]' robw.fyi
terraform -chdir=registrar import 'namecheap_domain_records.domain["flakery.xyz"]' flakery.xyz
terraform -chdir=registrar plan
```

Review before applying: `OVERWRITE` mode can overwrite registrar records.
Namecheap API source-IP allowlist:
https://ap.www.namecheap.com/settings/tools/apiaccess/whitelisted-ips.

## Publication

Credentials, state, plans, and provider caches are excluded from Git. Provider
lockfiles are versioned. The source reveals domains, DNS targets, service names,
AWS resource identifiers, and a public DNS verification record.
Rotate the Namecheap API key previously hardcoded in the local source.
