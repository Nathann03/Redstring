output "instance_id" {
  value = aws_instance.redstring_dialogue.id
}

output "public_ip" {
  value = aws_instance.redstring_dialogue.public_ip
}

output "api_url" {
  value = "http://${aws_instance.redstring_dialogue.public_ip}:${var.api_port}"
}
