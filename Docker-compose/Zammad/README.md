# Zammad Docker Compose Setup

This repository provides a Docker Compose setup for deploying a Zammad instance with Elasticsearch. Zammad is a web-based, open-source helpdesk software that is designed to be easy to use and to integrate with other software. This setup is optimized for environments with limited resources, specifically designed to run on systems with 2 CPUs and 4GB of memory.

## Features

- **Zammad**: The core helpdesk software, providing ticketing, issue tracking, and customer support functionalities.
- **Elasticsearch**: A powerful search and analytics engine that enhances the search capabilities of Zammad.
- **Docker Compose**: Simplifies the deployment and management of the application stack.

## Prerequisites

- Docker installed on your system.
- Docker Compose installed on your system.

## Getting Started

1. **Clone the Repository**: First, clone this repository to your local machine.
2. **Navigate to the Project Directory**: Change your current directory to the cloned repository.
3. **Start the Services**: Run the following command to start the Zammad and Elasticsearch services using Docker Compose.
   ```
   docker-compose up -d
   ```
4. **Access Zammad**: Once the services are up and running, you can access the Zammad web interface by navigating to `http://localhost:8080` in your web browser.

## Configuration

You can customize the Zammad and Elasticsearch configurations by editing the `docker-compose.yml` file and the `.env` file.

## Acknowledgments

- Zammad for providing an excellent helpdesk solution.
- Elasticsearch for enhancing search capabilities.
- Docker and Docker Compose for simplifying deployment.