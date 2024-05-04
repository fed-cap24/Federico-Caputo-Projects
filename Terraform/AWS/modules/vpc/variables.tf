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
}

variable "vpcCidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "PublicSubnet-List" {
  type = list(object({
    name    = string
    az      = number
    newbits = number
    netnum  = number
  }))
  default = [
    {
      name    = "Public_0"
      az      = 0
      newbits = 8
      netnum  = 10
    },
    {
      name    = "Public_1"
      az      = 1
      newbits = 8
      netnum  = 11
    }
  ]
}

variable "PrivateSubnet-List" {
  type = list(object({
    name    = string
    az      = number
    newbits = number
    netnum  = number
  }))
  default = [
    {
      name    = "Private_0"
      az      = 0
      newbits = 8
      netnum  = 20
    },
    {
      name    = "Private_1"
      az      = 1
      newbits = 8
      netnum  = 21
    }
  ]
}