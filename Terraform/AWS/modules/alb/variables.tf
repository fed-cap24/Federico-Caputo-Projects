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

variable "internal"{
  description = "Define if the load balancer is internal or internet facing (false == internet facing)"
  type        = bool
  default     = false
}

variable "alb_sg"{
  description = "List of security groups to allow access to the Application Load Balancer"
  type = list(string)
  default = []
}

variable "vpc" {
  description = "VPC configuration for the load balancer"
  type        = object({
    id              = string
    private_subnet  = list(string)
    public_subnet   = list(string)
  })
}

variable "listeners"{
  description = "set of all listeners for the load balancer. Each listener can have a list of redirect rules"

  type = set(object({
    port        = string
    protocol    = string
    ssl_policy  = optional(string)
    certificate_arn = optional(string)

    default_action = object({
      forward_target_group_arn = optional(string)
      redirect         = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
      fixed_response   = optional(object({
        content_type  = string
        message_body  = string
        status_code   = string
      }))
      authenticate_oidc = optional(object({
        authorization_endpoint  = string
        client_id               = string
        client_secret           = string
        issuer                  = string
        token_endpoint          = string
        user_info_endpoint      = string
      }))
      authenticate_cognito = optional(object({
        user_pool_arn       = string
        user_pool_client_id = string
        user_pool_domain    = string
      }))
    })

    rules = optional(list(object({
      action = object({
        forward_target_group_arn = optional(string)
        redirect         = optional(object({
          port        = string
          protocol    = string
          status_code = string
        }))
        fixed_response   = optional(object({
          content_type  = string
          message_body  = string
          status_code   = string
        }))
        authenticate_oidc = optional(object({
          authorization_endpoint  = string
          client_id               = string
          client_secret           = string
          issuer                  = string
          token_endpoint          = string
          user_info_endpoint      = string
        }))
        authenticate_cognito = optional(object({
          user_pool_arn       = string
          user_pool_client_id = string
          user_pool_domain    = string
        }))
      })

      condition = object({
        host_header   = optional(list(string))
        
        path_pattern  = optional(list(string))
        
        http_header   = optional(object({
          http_header_name = string
          values           = list(string)
        }))

        http_request_method = optional(list(string))

        http_code = optional(list(string))

        source_ip = optional(list(string))

        query_string = optional(object({
          key = string
          value = string
        }))
      })
    })))
  }))

  default = [{
    port      = "80"
    protocol  = "HTTP"

    default_action = {
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed response (default terraform module)"
        status_code  = "200"
      }
    }
  }]

  validation {
    condition     = alltrue([
      for listener in var.listeners : length([
        for action in [
          listener.default_action.forward_target_group_arn,
          listener.default_action.redirect,
          listener.default_action.fixed_response,
          listener.default_action.authenticate_oidc,
          listener.default_action.authenticate_cognito
        ] : action if action != null
      ]) ==  1
    ])
    error_message = "The default_action object must have exactly one action specified. Choose one of 'forward_target_group_arn', 'redirect', 'fixed_response', 'authenticate_oidc', or 'authenticate_cognito'."
  }

  validation {
    condition     = alltrue([
      for listener in var.listeners : alltrue([
        for rule in listener.rules : length([
        for action in [
          listener.default_action.forward_target_group_arn,
          listener.default_action.redirect,
          listener.default_action.fixed_response,
          listener.default_action.authenticate_oidc,
          listener.default_action.authenticate_cognito
        ] : action if action != null
      ]) ==  1
      ]) if listener.rules != null
    ])
    error_message = "Each action of every rule in the set of optional rules must have exactly one of either 'forward_target_group_arn', 'redirect', 'fixed_response', 'authenticate_oidc', or 'authenticate_cognito'."
  }

  validation {
    condition     = alltrue([
      for listener in var.listeners : (listener.protocol != "HTTPS" || (listener.ssl_policy != null && listener.certificate_arn != null))
    ])
    error_message = "If the protocol is 'HTTPS', both 'ssl_policy' and 'certificate_arn' must be explicitly defined."
  }

  validation {
  condition     = alltrue([
    for listener in var.listeners : contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP"], listener.protocol)
   ])
    error_message = "The protocol must be one of the following: HTTP, HTTPS, TCP, TLS, UDP, TCP_UDF."
  }
}

variable "lock_security_groups"{
  description = "Map of security groups with ingress rules from the load balancer. This will generate security groups which should be placed in the appropriate resources"

  type = map(object({
    description = optional(string, "Lock security group created by Terraform")
    ingress = set(object({
      from_port = number
      to_port   = number
      protocol  = string
      description = optional(string)
    }))
  }))

  default = {
    App = {
      description = "Lock security group for port 80"
      ingress = [
        {
          from_port = 80
          to_port   = 80
          protocol  = "tcp"
          description = "Allow access to port 80"
        }
      ]
    }
  }
}

variable "target_groups" {
  type = map(object({
    port        = optional(number,80)
    protocol    = optional(string,"HTTP")
    target_type = optional(string,"ip")

    healthCheck  = optional(object({
        enabled        = optional(bool, true)
        interval       = optional(number,  60)
        path           = optional(string, "/")
        port           = optional(number, -1)
        protocol       = optional(string, "HTTP")
        timeout        = optional(number,  30)
        healthy_threshold = optional(number,  3)
        unhealthy_threshold = optional(number,  2)
        matcher        = optional(string, "200-299")
      }), {
        enabled  = true
        interval = 60
        path     = "/"
        port     = -1
        protocol = "HTTP"
        timeout  = 30
        healthy_threshold = 3
        unhealthy_threshold = 2
        matcher = "200-299"
      })
  }))

  default = {}
}