"""Run once in authenticated AWS CloudShell after reviewing iam/*.json.

Creates a private state bucket, a DNS-only IAM user (without credentials), and
a main-branch GitHub OIDC role. Upload the migrated state separately.
"""
import json
from pathlib import Path

import boto3

ACCOUNT = "390825964154"
BUCKET = "r33drichards-dns-tfstate-" + ACCOUNT
session = boto3.Session(region_name="us-east-1")
assert session.client("sts").get_caller_identity()["Account"] == ACCOUNT
iam = session.client("iam")
s3 = session.client("s3")
policy = Path("iam/dns-policy.json").read_text()
trust = Path("iam/github-trust.json").read_text()
json.loads(policy)
json.loads(trust)
iam.get_open_id_connect_provider(
    OpenIDConnectProviderArn=f"arn:aws:iam::{ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
)

# Refuse to overwrite existing identities or bucket configuration.
for lookup, kwargs in [
    (iam.get_role, {"RoleName": "github-dns"}),
    (iam.get_user, {"UserName": "dns-local"}),
]:
    try:
        lookup(**kwargs)
    except iam.exceptions.NoSuchEntityException:
        pass
    else:
        raise SystemExit("Identity already exists; inspect it before proceeding.")
if BUCKET in [b["Name"] for b in s3.list_buckets()["Buckets"]]:
    raise SystemExit("State bucket already exists; inspect it before proceeding.")

s3.create_bucket(Bucket=BUCKET)
s3.put_public_access_block(Bucket=BUCKET, PublicAccessBlockConfiguration={
    "BlockPublicAcls": True, "IgnorePublicAcls": True,
    "BlockPublicPolicy": True, "RestrictPublicBuckets": True,
})
s3.put_bucket_versioning(Bucket=BUCKET, VersioningConfiguration={"Status": "Enabled"})
s3.put_bucket_encryption(Bucket=BUCKET, ServerSideEncryptionConfiguration={
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
})
s3.put_bucket_policy(Bucket=BUCKET, Policy=json.dumps({
    "Version": "2012-10-17", "Statement": [{
        "Sid": "RequireTLS", "Effect": "Deny", "Principal": "*",
        "Action": "s3:*", "Resource": [f"arn:aws:s3:::{BUCKET}", f"arn:aws:s3:::{BUCKET}/*"],
        "Condition": {"Bool": {"aws:SecureTransport": "false"}},
    }],
}))
iam.create_user(UserName="dns-local", Tags=[{"Key": "Project", "Value": "dns"}])
iam.put_user_policy(UserName="dns-local", PolicyName="DNSProject", PolicyDocument=policy)
iam.create_role(RoleName="github-dns", AssumeRolePolicyDocument=trust,
                MaxSessionDuration=3600, Tags=[{"Key": "Project", "Value": "dns"}])
iam.put_role_policy(RoleName="github-dns", PolicyName="DNSProject", PolicyDocument=policy)
print("Created private versioned state bucket, dns-local user without keys, and github-dns OIDC role.")
