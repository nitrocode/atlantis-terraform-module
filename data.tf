provider "aws" {
  region = local.region
}

data "aws_acm_certificate" "internal" {
  domain = "*"
  types  = ["AMAZON_ISSUED"]
}

data "aws_vpc" "selected" {
  tags = {
    Name = "default"
  }
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Name = "public"
  }
}

data "aws_subnet" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Name = "private"
  }
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
