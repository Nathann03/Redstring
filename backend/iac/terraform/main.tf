terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "redstring_dialogue" {
  name        = "${var.project_name}-sg"
  description = "Security group for RedString dialogue API"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.operator_cidr]
  }

  ingress {
    description = "Dialogue API"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "redstring_dialogue" {
  name               = "${var.project_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.redstring_dialogue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "optional_s3_read" {
  count = var.model_s3_bucket_arn == "" ? 0 : 1

  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      var.model_s3_bucket_arn,
      "${var.model_s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "optional_s3_read" {
  count  = var.model_s3_bucket_arn == "" ? 0 : 1
  name   = "${var.project_name}-s3-read"
  role   = aws_iam_role.redstring_dialogue.id
  policy = data.aws_iam_policy_document.optional_s3_read[0].json
}

resource "aws_iam_instance_profile" "redstring_dialogue" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.redstring_dialogue.name
}

resource "aws_instance" "redstring_dialogue" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.redstring_dialogue.id]
  iam_instance_profile        = aws_iam_instance_profile.redstring_dialogue.name
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  dynamic "instance_market_options" {
    for_each = var.use_spot ? [1] : []

    content {
      market_type = "spot"

      spot_options {
        instance_interruption_behavior = "stop"
        spot_instance_type             = "persistent"
      }
    }
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gb
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_port = var.api_port
  })

  tags = {
    Name = var.project_name
  }
}
