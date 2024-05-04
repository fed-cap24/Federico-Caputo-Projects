variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = ""
}

variable "project-tags" {
  type = map(string)
  default = {
    project =   "TestProject"
  }
}

variable "hubmobeats" {
  type = map(string)

  default = {
    username = "ciuser"
    password = "M0b34ts!"
  }
}