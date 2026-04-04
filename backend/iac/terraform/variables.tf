variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "redstring-dialogue"
}

variable "ami_id" {
  type        = string
  description = "Deep Learning Base OSS Nvidia Driver GPU AMI ID for your region."
}

variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"
}

variable "use_spot" {
  type    = bool
  default = true
}

variable "root_volume_size_gb" {
  type    = number
  default = 80
}

variable "api_port" {
  type    = number
  default = 8000
}

variable "operator_cidr" {
  type        = string
  description = "Your public IP in CIDR form, for example 203.0.113.10/32."
}

variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name."
}

variable "model_s3_bucket_arn" {
  type    = string
  default = ""
}
