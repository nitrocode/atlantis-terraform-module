module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "~> 2.30.0"

  name = local.name

  vpc_id = data.aws_vpc.selected.id

  public_subnet_ids  = local.public_subnet_ids
  private_subnet_ids = local.private_subnet_ids

  # this has to be set to true since subnets are all public
  # ecs_service_assign_public_ip = true

  # DNS (without trailing dot)
  route53_zone_name = local.route53_zone_name

  certificate_arn = data.aws_acm_certificate.internal.arn

  # Atlantis
  # atlantis_github_user       = "mybot"
  # atlantis_github_user       = "fake"
  # This becomes ATLANTIS_GH_WEBHOOK_SECRET environment variable
  # atlantis_github_user_token = base64decode(data.aws_s3_bucket_object.github_user_token.body)
  # atlantis_github_user_token = base64decode(data.aws_s3_bucket_object.github_webhook_secret.body)

  # When true allows the use of atlantis.yaml config files within the source repos.
  # Deprecated and insecure so this is disabled.
  # allow_repo_config = "true"

  # create custom container
  # Fill this in with the custom container endpoint
  # atlantis_image = "${aws_ecr.this.registry_url}:latest"

  # List of allowed repositories Atlantis can be used with
  # If this isn't set to all company then it will post a comment on every PR saying that
  # it's not allowed to work with this repo....
  atlantis_repo_whitelist = [
    "github.com/company/*",
  ]

  # Atlantis
  # Github repositories where webhook should be created
  atlantis_allowed_repo_names = [
    "company/terraform"
  ]

  # allow unauthenticated access from github
  # This adds an additional listener rule to bypass the oidc authentication above
  allow_unauthenticated_access = true
  allow_github_webhooks        = true

  # atlantis_log_level = "info"

  atlantis_hide_prev_plan_comments = "true"

  # This defaults to true but if we create the private record outside this
  # module, perhaps we should create the public record outside as well.
  create_route53_record = true

  # The `ATLANTIS_WRITE_GIT_CREDS` allows writing creds to a file so
  # private modules from our org can be used by atlantis when running
  # terraform init.
  custom_environment_variables = [
    {
      "name" : "ATLANTIS_WRITE_GIT_CREDS",
      "value" : "true",
    },
    # Override server config
    {
      "name" : "ATLANTIS_REPO_CONFIG_JSON",
      "value" : local.repo_config_json,
    },
    # Better to disable by echoing a message instead
    #    {
    #      "name" : "ATLANTIS_DISABLE_APPLY_ALL",
    #      "value" : "1",
    #    }
    # set default version
    {
      "name" : "ATLANTIS_DEFAULT_TF_VERSION",
      "value" : local.terraform_version,
    },
    {
      "name" : "DEFAULT_TERRAFORM_VERSION",
      "value" : local.terraform_version,
    },
    # for the github bot
    {
      "name" : "ATLANTIS_GH_APP_ID",
      "value" : "<appid>",
    },
    {
      "name" : "ATLANTIS_GH_APP_KEY_FILE",
      "value" : "/home/atlantis/atlantis-app-key.pem",
    },
    {
      "name" : "ATLANTIS_GH_WEBHOOK_SECRET",
      "value" : "<secret>",
    },
  ]

  # Add all the policies of the engineer role
  policies_arn = [
    data.aws_iam_policy.ecs_task_execution.arn
  ]

  tags = local.tags
}
