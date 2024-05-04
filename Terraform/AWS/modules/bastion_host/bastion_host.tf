## Get most recent AMI for an Amazon Linux 2 instance

data "aws_ami" "amazon_linux_2_bastion" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

## Make Elastic IP

resource "aws_eip" "bastion" {
  domain = "vpc"
  tags   = var.tags
}

## Create a public and private key pair for login to the Bastion Host

resource "aws_key_pair" "bastion" {
  key_name   = local.name-prefix != "" ? "${local.name-prefix}_Bastion_Key" : "Bastion_Key"
  public_key = var.public_key
  tags       = var.tags
}

## Make Bastion Resource

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2_bastion.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.bastion.key_name

  vpc_security_group_ids = [var.bastion_sg]

  subnet_id = var.vpc.public_subnet[0]

  tags = merge(
    var.tags,
    {
    Name        = local.name-prefix != "" ? "${local.name-prefix}_Bastion" : "Bastion" 
    Description = local.name-prefix != "" ? "Bastion host for access to elements in private subnets such as RDS, ECS instances and private EC2 instances. Used in ${local.name-prefix}" : "Bastion host for access to elements in private subnets such as RDS, ECS instances and private EC2 instances."
    }
  )
}

## Associate Bastion Resource to Elastic IP

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}