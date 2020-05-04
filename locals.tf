locals {
  region = "us-east-1"

  name = "atlantis"
  team = "sre"
  env  = "production"

  tags = {
    Name = local.name,
    team = local.team
    env  = local.env
  }

  public_subnet_ids = [
    data.aws_subnet.public.id,
  ]

  private_subnet_ids = [
    data.aws_subnet.private.id,
  ]

  route53_zone_name = "internal.company.com"

  # read from yaml file, decode into json, encode into a string
  repo_config_json = jsonencode(
    yamldecode(
      file("${path.module}/atlantis.yaml")
    )
  )
}
