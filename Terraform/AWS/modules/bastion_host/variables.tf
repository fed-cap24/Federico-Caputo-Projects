variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

locals {
  # This local value constructs a prefix for resource names based on the presence of
  # 'application' and 'environment' tags. If both are present, it combines them with a hyphen.
  # If only one is present, it uses that value. If neither is present, it defaults to an empty string.
  name-prefix = lookup(var.tags, "application", "") != "" && lookup(var.tags, "environment", "") != "" ? "${lookup(var.tags, "application")}_${lookup(var.tags, "environment")}" : lookup(var.tags, "application", "") != "" ? lookup(var.tags, "application") : lookup(var.tags, "environment", "")

  bastion-sg-name = local.name-prefix != "" ? "${local.name-prefix}_Bastion_Access_SG" : "Bastion_Access_SG"
}

variable "vpc" {
  description = "VPC configuration for the Bastion Host"
  type        = object({
    id              = string
    private_subnet  = list(string)
    public_subnet   = list(string)
  })
}

variable "bastion_sg"{
  description = "ID of SG which allows access from approved locations to bastion Host"
  type        = string
}

variable "public_key" {
  description = "Public key for the bastion host"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key for the bastion host"
  type        = string
  default     = "./bastion_key.pem"
}
variable "username" {
  description = "Default username of the AMI for the bastion host. This is used only in case that this value changes from ec2-user"
  type        = string
  default     = "ec2-user"
}