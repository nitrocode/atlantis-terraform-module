plugin "aws" {
  enabled    = true
  deep_check = true
}

config {
  module = true
}

# missing tags
rule "aws_resource_missing_tags" {
  enabled = true
  exclude = [
    # this is covered by the propagation already
    "aws_autoscaling_group",
    # this has to be enabled on the account level which may break things
    "aws_ecs_service"
  ]
  tags = ["env", "application", "team"]
}

# using an older generation
rule "aws_instance_previous_type" {
  enabled = true
}

# using an invalid type
rule "aws_instance_invalid_type" {
  enabled = true
}

# all modules should be pinned instead of using master
rule "terraform_module_pinned_source" {
  enabled = true
}

# throw a message if an unused variable is declared
rule "terraform_unused_declarations" {
  enabled = true
}
