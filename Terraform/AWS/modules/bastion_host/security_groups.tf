## Create Security group to allow access from Bastion Host to Instances or RDS

resource "aws_security_group" "bastion_access" {
  vpc_id      = var.vpc.id

  name        = local.bastion-sg-name
  description = "Allow SSH access from the Elastic IP of the ${local.bastion-sg-name}"

    ingress {
    from_port   =   22
    to_port     =   22
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.bastion.public_ip}/32"]
    description     = "Allow SSH Access"
    }

    ingress {
    from_port   =  22
    to_port     =  22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
    description = "Allow SSH access from Bastion Host private IP"
    }

    ingress {
        from_port       = 1433
        to_port         = 1433
        protocol        = "tcp"
        cidr_blocks = ["${aws_eip.bastion.public_ip}/32"]
        description     = "Allow SQL Server Access"
    }

    ingress {
        from_port       = 1433
        to_port         = 1433
        protocol        = "tcp"
        cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
        description     = "Allow SQL Server Access from Bastion Host private IP"
    }

    ingress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        cidr_blocks = ["${aws_eip.bastion.public_ip}/32"]
        description     = "Allow MySQL Access"
    }

    ingress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
        description     = "Allow SQL Server Access from Bastion Host private IP"
    }

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        cidr_blocks = ["${aws_eip.bastion.public_ip}/32"]
        description     = "Allow PostgreSQL Access"
    }

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
        description     = "Allow PostgreSQL Access from Bastion Host private IP"
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

  tags = merge(
    var.tags,
    {
    Name = local.bastion-sg-name
    }
  )
}