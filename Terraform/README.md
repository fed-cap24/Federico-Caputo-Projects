# Terraform Infrastructure as Code Projects

This repository contains a collection of Terraform scripts and modules designed to automate the provisioning of cloud infrastructure on various providers. 

## Project Structure

The project is organized into a hierarchical structure that separates root projects from reusable modules. This approach allows for easy management and reuse of Terraform configurations across different environments and projects.

### Root Projects

For each cloud provider, there is a dedicated folder for each root projects. These projects serve as the entry points for deploying infrastructure on the respective provider. Each root project is tailored to a specific use case or environment, such as setting up an ECS cluster or deploying a web application.

### Modules

Within each provider's folder, there is a `modules` directory. This directory contains reusable Terraform modules that encapsulate common infrastructure components. These modules can be easily integrated into root projects to streamline the deployment process and ensure consistency across environments.

### AWS ECS Project

Within the AWS provider folder, there is a specific project dedicated to setting up an ECS environment. This project includes configurations for ECS clusters, services, tasks, and related resources. It also leverages the reusable modules for components such as Application Load Balancers, security groups, and IAM roles.

## Getting Started

To get started with this project, clone the repository and navigate to the root project of interest. Follow the instructions in the README file within that project to deploy the infrastructure.