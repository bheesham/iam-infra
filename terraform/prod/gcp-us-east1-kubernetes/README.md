# How to apply

These configs are multi-cloud, so you'll need to authenticate to both Google
and AWS.

## Authenticating to GCP

Run the following:

```
gcloud auth application-default login
```

## Authenticating to AWS

Ensure the following exists in your `~/.aws/confg`:

```
[profile iam-admin]
sso_session = mozilla
sso_account_id = 320464205386
sso_role_name = AdministratorAccess
sso_region = us-west-2
sso_start_url = https://mozilla-aws.awsapps.com/start#

[sso-session mozilla]
sso_start_url = https://mozilla-aws.awsapps.com/start#
sso_region = us-west-2
sso_registration_scopes = sso:account:access
```

Create a SSO Session:

```
aws sso login --sso-session mozilla
```

If you don't have direnv, something along the lines of the following should
work:

```
$(aws configure export-credentials --format env --profile iam-admin)
```

If you _do_ have direnv, then `cd`ing into this directory should just Do The
Thing.
