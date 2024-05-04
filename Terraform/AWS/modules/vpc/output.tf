output "id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet" {
  value       = values(aws_subnet.public)[*].id
  description = "Public Subnets ID"
}

output "private_subnet" {
  value       = values(aws_subnet.private)[*].id
  description = "Private Subnets ID"
}