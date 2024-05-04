# VPC Module
## Overview

This Terraform module provides a reusable and modular approach to provisioning and managing Virtual Private Cloud (VPC) resources on Amazon Web Services (AWS). The module is designed to simplify the deployment and maintenance of VPC infrastructure by encapsulating the creation of various VPC components such as subnets, security groups, route tables, and more.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the VPC infrastructure:

- `variables.tf`: Defines the input variables that the module requires, such as tags, AWS region, and VPC settings.
- `cloudwatch.tf`: Sets up CloudWatch log groups for VPC flow logs, enabling monitoring and analysis of network traffic within the VPC.
- `iam.tf`: Configures IAM roles and policies necessary for VPC flow logs to publish to CloudWatch log groups.
- `vpc.tf`: Provisions the core VPC resources, including the VPC itself, subnets, internet gateways, NAT gateways, and route tables.

## How It Works

### Input Variables

The module accepts input variables that allow customization of the VPC infrastructure. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `vpcCidr`: The CIDR block for the VPC.
- `PublicSubnet-List` and `PrivateSubnet-List`: Lists of objects defining the public and private subnets, including their names, availability zones, and CIDR ranges.

### Naming convention

The module generates a name-prefix to be used in all resources based on the tags of the application. if tags has an `application` and/or `environment` tag, it will add these to the names. This allows to reuse the module in differenet applications and environments in the same account.

### CloudWatch Logs

The module sets up a CloudWatch log group for VPC flow logs. These logs capture information about the IP traffic going to and from network interfaces in the VPC, which can be useful for monitoring, troubleshooting, and security analysis. The log group is configured with a retention period of  30 days and is tagged with the `Name` tag derived from the `local.name-prefix`.

### IAM Roles and Policies

An IAM role and policy are created to allow VPC flow logs to publish to the CloudWatch log group. The role is granted permissions to perform actions related to CloudWatch logs, and the policy is attached to the role to define these permissions.

### VPC Resources

The core VPC resources are provisioned using the `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_nat_gateway`, and `aws_route_table` resources. These resources are configured with the input variables provided to the module. The VPC is set up with DNS support enabled, and subnets are created according to the `PublicSubnet-List` and `PrivateSubnet-List` variables. NAT gateways are provisioned for private subnets, and route tables are configured to direct traffic through the internet gateway or NAT gateways as appropriate.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "vpc" {
  source = "./modules/vpc"

  tags = {
    environment = "Production"
    application = "MyApp"
  }
}
```
By default, it will create 2 public subnets and 2 private subnets in az 0 and 1 (a and b), with vpcCidr 10.1.0.0/16.
However, you can modify the default by adding the rest of the variables:

```hcl
module "vpc" {
  source = "./modules/vpc"

  tags = {
    environment = "Production"
    application = "MyApp"
  }

  vpcCidr    = "10.1.0.0/16"

  PublicSubnet-List = [
    {
      name    = "Public_0"
      az      =  0
      newbits =  8
      netnum  =  10
    },
    // ... additional public subnets ...
  ]

  PrivateSubnet-List = [
    {
      name    = "Private_0"
      az      =  0
      newbits =  8
      netnum  =  20
    },
    // ... additional private subnets ...
  ]
}
```


After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the VPC infrastructure.

## Outputs

The module outputs the IDs and ARNs of the created resources, which can be used as inputs to other modules or for further configuration.

## Outputs

The module outputs the following attributes:

- **id**: The ID of the VPC.
- **public_subnet**: A list of the IDs of the public subnets.
- **private_subnet**: A list of the IDs of the private subnets.