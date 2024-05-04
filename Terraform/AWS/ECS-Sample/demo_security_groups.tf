resource "aws_security_group" "bastion" {
    vpc_id       =   module.demo_vpc.id
    name         =   "Bastion_SG"
    description =   "Security group for bastion host. It should allow access from approved locations through SSH"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        description     = "IP public"
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {Name = "Bastion_SG"}
}

resource "aws_security_group" "http_https" {
    vpc_id          =   module.demo_vpc.id
    name            =   "HTTP_HTTPS"
    description     =   "Allow HTTP and HTTPs Access"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        description     = "Allow HTTP access"
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        description     = "Allow HTTPs access"
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = { Name = "HTTP_HTTPS" }
}