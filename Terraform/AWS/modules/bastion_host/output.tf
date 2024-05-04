output "public_ip" {
    value       = aws_eip.bastion.public_ip
    description = "Bastion Host Elastic IP"
}

output "user" {
    value       = var.username
    description = "Default username for the Bastion Host"
}

output "private_key_path" {
    value       = var.private_key_path
    description = "Path to private key of the Bastion Host"
}

output "sg_bastion_access_id"{
    value       = aws_security_group.bastion_access.id
    description = "ID of Security group which will allow access to ssh, MySQL, PostgreSQL and SQL from Bastion"
}

output "vpc"{
    value       = var.vpc
    description = "Output the current VPC so other modules have access to the same vpc"
}