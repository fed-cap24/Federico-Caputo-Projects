# Bastion Host Module

## Overview

This Terraform module provides a reusable and modular approach to provisioning and managing a Bastion Host on Amazon Web Services (AWS). The module simplifies the deployment and maintenance of a secure entry point into a private network by encapsulating the creation of the Bastion Host instance, its associated security group, and the necessary networking configurations.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the Bastion Host infrastructure:

- `bastion_host.tf`: Defines the AWS resources for the Bastion Host, including the instance, Elastic IP, and key pair.
- `variables.tf`: Specifies the input variables that the module requires, such as tags, VPC configuration, security group ID, and SSH keys.
- `output.tf`: Declares the output variables that expose the Bastion Host's public IP address, default username, private key path, and security group ID.
- `security_groups.tf`: Creates the security group that controls access to the Bastion Host, allowing SSH and database access from the Bastion Host's Elastic IP.

## How It Works

### Input Variables

The module accepts input variables that allow customization of the Bastion Host infrastructure. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `vpc`: An object containing the VPC ID and lists of public and private subnet IDs.
- `bastion_sg`: The ID of the security group that allows access from approved locations to the Bastion Host.
- `public_key`: The public key for the Bastion Host.
- `private_key_path`: The path to the private key for the Bastion Host.
- `username`: The default username for the Bastion Host (defaults to `ec2-user`).

### Naming Convention

The module generates a name-prefix for all resources based on the tags of the application. If tags have an `application` and/or `environment` tag, it will add these to the names. This allows reusing the module across different applications and environments within the same account.

### Security Group Configuration

An AWS security group is created to allow access from the Bastion Host. It allows SSH and database (MySQL, SQL Server, and PostgreSQL) access from the Bastion Host's Elastic IP.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "bastion_host" {
  source = "./modules/bastion_host"

  tags = {
    environment = "Production"
    application = "MyApp"
  }

  vpc = module.vpc

  bastion_sg = "sg-abcdefgh"

  public_key = "{YOUR-PUBLIC-KEY}"
}
```

After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the Bastion Host infrastructure.

## Outputs

The module outputs the following attributes:

- **public_ip**: The Elastic IP address of the Bastion Host.
- **user**: The default username for the Bastion Host.
- **private_key_path**: The path to the private key of the Bastion Host.
- **sg_bastion_access_id**: The ID of the security group that allows access to the Bastion Host.
- **vpc**: The current vpc of the Bastion Host, for future use.

By using these outputs, you can retrieve the necessary information for accessing the Bastion Host and integrating it with other systems or modules.