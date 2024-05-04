# Zabbix Docker Compose Setup

This repository contains a Docker Compose configuration for deploying Zabbix Agent and Proxy. The setup is designed to enable monitoring of the host system and other Docker containers running within the same environment.

## Features

- **Zabbix Agent**: Monitors the host system and other Docker containers.
- **Zabbix Proxy**: Acts as an intermediary for Zabbix Agents, allowing for scalable monitoring of a large number of hosts.

## Configuration

- **Zabbix Agent**: The agent configuration can be found in the `docker-compose-agent.yml` file under the `zabbix-agent` service.
- **Zabbix Proxy**: The proxy configuration can be found in the `docker-compose-proxy.yml` file under the `zabbix-proxy` service.

## Acknowledgments
- Zabbix for the monitoring solution.
- Docker and Docker Compose for simplifying deployment.