# providers.tf
terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 5.3"
    }
    jwt = {
      source  = "camptocamp/jwt"  
      version = "~> 1.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
  required_version = ">= 1.8.0"  # Provider functions need 1.8+
}

resource "jwt_signed_token" "okta_assertion" {
  algorithm = "RS256"
  
  key = var.okta_private_key
  
  claims_json = jsonencode({
    aud = "https://${var.okta_org_name}.${var.okta_base_url}/oauth2/v1/token"
    iss = var.okta_client_id
    sub = var.okta_client_id
    jti = uuid()
    kid = var.okta_private_key_id
    iat = provider::time::rfc3339_parse(timestamp()).unix
    exp = provider::time::rfc3339_parse(timestamp()).unix + 3600
  })
}

data "http" "okta_token" {
  url    = "https://${var.okta_org_name}.${var.okta_base_url}/oauth2/v1/token"
  method = "POST"
  
  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }
  
  request_body = "grant_type=client_credentials&scope=${join("+", [
    "okta.policies.manage",
    "okta.policies.read", 
    "okta.authenticators.manage",
    "okta.authenticators.read"
  ])}&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=${jwt_signed_token.okta_assertion.token}"
}

locals {
  token_response = jsondecode(data.http.okta_token.response_body)
  access_token = local.has_error ? "" : local.token_response.access_token
  has_error = can(local.token_response.error)
  error_message = local.has_error ? "${local.token_response.error}: ${lookup(local.token_response, "error_description", "No description")}" : ""
}


provider "okta" {
  org_name       = var.okta_org_name
  base_url       = var.okta_base_url
  client_id      = var.okta_client_id
  private_key_id = var.okta_private_key_id
  private_key    = var.okta_private_key
  scopes    = [
    "okta.policies.manage",
    "okta.policies.read", 
    "okta.authenticators.manage",
    "okta.authenticators.read"
  ]
}
