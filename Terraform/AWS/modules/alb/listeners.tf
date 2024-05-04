resource "aws_lb_listener" "lb_listener" {
  for_each = { for listener in var.listeners : listener.port => listener}

  load_balancer_arn = aws_lb.alb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  default_action {
      type = each.value.default_action.forward_target_group_arn != null ? "forward" : each.value.default_action.redirect != null ? "redirect" : each.value.default_action.fixed_response != null ? "fixed-response" : each.value.default_action.authenticate_oidc != null ? "authenticate-oidc" : "authenticate-cognito"
      
      target_group_arn = each.value.default_action.forward_target_group_arn

      dynamic "redirect"{
        for_each = each.value.default_action.redirect != null ? [1] : []
        content {
          port        = each.value.default_action.redirect.port
          protocol    = each.value.default_action.redirect.protocol
          status_code = each.value.default_action.redirect.status_code
        }
      }

      dynamic "fixed_response"{
        for_each = each.value.default_action.fixed_response != null ? [1] : []
        content {
          content_type  = each.value.default_action.fixed_response.content_type
          message_body  = each.value.default_action.fixed_response.message_body
          status_code   = each.value.default_action.fixed_response.status_code
        }
      }
      
      dynamic "authenticate_oidc"{
        for_each = each.value.default_action.authenticate_oidc != null ? [1] : []
        content {
          authorization_endpoint  = each.value.default_action.authenticate_oidc.authorization_endpoint
          client_id               = each.value.default_action.authenticate_oidc.client_id
          client_secret           = each.value.default_action.authenticate_oidc.client_secret
          issuer                  = each.value.default_action.authenticate_oidc.issuer
          token_endpoint          = each.value.default_action.authenticate_oidc.token_endpoint
          user_info_endpoint      = each.value.default_action.authenticate_oidc.user_info_endpoint
        }
      }

      dynamic "authenticate_cognito"{
        for_each = each.value.default_action.authenticate_cognito != null ? [1] : []
        content {
          user_pool_arn       = each.value.default_action.authenticate_cognito.user_pool_arn
          user_pool_client_id = each.value.default_action.authenticate_cognito.user_pool_client_id
          user_pool_domain    = each.value.default_action.authenticate_cognito.user_pool_domain
        }
      }
  }
}


## Flatten all listeners for listener rules. Each element will hold the port, the index of the rule (for priority reasons) and the rule itself

locals {
  listeners_flattened = toset(flatten([
    for listener in var.listeners : [
      for rule_index, rule in listener.rules : merge({port = listener.port}, {
        index = rule_index + 1
        rule  = rule
      })
    ] if listener.rules != null
   ]))
  
  listener_rules = {for listener in local.listeners_flattened : "${listener.port}_${listener.index}" => listener}

  listener_rules_IDs = toset(keys(local.listener_rules))
}

resource "aws_lb_listener_rule" "listener_rule" {
  for_each = local.listener_rules_IDs

  listener_arn = aws_lb_listener.lb_listener[local.listener_rules[each.value].port].arn
  priority     = local.listener_rules[each.value].index * 100

  action {
      type = local.listener_rules[each.value].rule.action.forward_target_group_arn != null ? "forward" : local.listener_rules[each.value].rule.action.redirect != null ? "redirect" : local.listener_rules[each.value].rule.action.fixed_response != null ? "fixed-response" : local.listener_rules[each.value].rule.action.authenticate_oidc != null ? "authenticate-oidc" : "authenticate-cognito"
      
      target_group_arn = local.listener_rules[each.value].rule.action.forward_target_group_arn
      
      dynamic "redirect"{
        for_each = local.listener_rules[each.value].rule.action.redirect != null ? [1] : []
        content {
          port        = local.listener_rules[each.value].rule.action.redirect.port
          protocol    = local.listener_rules[each.value].rule.action.redirect.protocol
          status_code = local.listener_rules[each.value].rule.action.redirect.status_code
        }
      }

      dynamic "fixed_response"{
        for_each = local.listener_rules[each.value].rule.action.fixed_response != null ? [1] : []
        content {
          content_type  = local.listener_rules[each.value].rule.action.fixed_response.content_type
          message_body  = local.listener_rules[each.value].rule.action.fixed_response.message_body
          status_code   = local.listener_rules[each.value].rule.action.fixed_response.status_code
        }
      }
      
      dynamic "authenticate_oidc"{
        for_each = local.listener_rules[each.value].rule.action.authenticate_oidc != null ? [1] : []
        content {
          authorization_endpoint  = local.listener_rules[each.value].rule.action.authenticate_oidc.authorization_endpoint
          client_id               = local.listener_rules[each.value].rule.action.authenticate_oidc.client_id
          client_secret           = local.listener_rules[each.value].rule.action.authenticate_oidc.client_secret
          issuer                  = local.listener_rules[each.value].rule.action.authenticate_oidc.issuer
          token_endpoint          = local.listener_rules[each.value].rule.action.authenticate_oidc.token_endpoint
          user_info_endpoint      = local.listener_rules[each.value].rule.action.authenticate_oidc.user_info_endpoint
        }
      }

      dynamic "authenticate_cognito"{
        for_each = local.listener_rules[each.value].rule.action.authenticate_cognito != null ? [1] : []
        content {
          user_pool_arn       = local.listener_rules[each.value].rule.action.authenticate_cognito.user_pool_arn
          user_pool_client_id = local.listener_rules[each.value].rule.action.authenticate_cognito.user_pool_client_id
          user_pool_domain    = local.listener_rules[each.value].rule.action.authenticate_cognito.user_pool_domain
        }
      }
  }

  condition {

    dynamic "host_header" {
      for_each = local.listener_rules[each.value].rule.condition.host_header != null ? [1] : []
      content {
        values = local.listener_rules[each.value].rule.condition.host_header
      }
    }

    dynamic "path_pattern" {
      for_each = local.listener_rules[each.value].rule.condition.path_pattern != null ? [1] : []
      content {
        values = local.listener_rules[each.value].rule.condition.path_pattern
      }
    }

    dynamic "http_header" {
      for_each = local.listener_rules[each.value].rule.condition.http_header != null ? [1] : []
      content {
        http_header_name = local.listener_rules[each.value].rule.condition.http_header.http_header_name
        values = local.listener_rules[each.value].rule.condition.http_header.values
      }
    }

    dynamic "http_request_method" {
      for_each = local.listener_rules[each.value].rule.condition.http_request_method != null ? [1] : []
      content {
        values = local.listener_rules[each.value].rule.condition.http_request_method
      }
    }
    
    dynamic "source_ip" {
      for_each = local.listener_rules[each.value].rule.condition.source_ip != null ? [1] : []
      content {
        values = local.listener_rules[each.value].rule.condition.source_ip
      }
    }

    dynamic "query_string" {
      for_each = local.listener_rules[each.value].rule.condition.query_string != null ? [1] : []
      content {
        key   = local.listener_rules[each.value].rule.condition.query_string.key
        value = local.listener_rules[each.value].rule.condition.query_string.value
      }
    }
  }
}