# providers.tf
# Okta provider configuration
terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 5.2"
    }
    restapi = {
      source  = "mastercard/restapi"
      version = "~> 1.19"
    }
    jwt = {
      source  = "camptocamp/jwt"  
      version = "~> 1.1"
    }
  }
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

resource "jwt_hashed_token" "okta_assertion" {
  algorithm = "RS256"
  
  # Use 'secret' instead of 'private_key'
  secret = var.okta_private_key
  
  # Use 'claims_json' instead of 'claims'
  claims_json = jsonencode({
    aud = "https://${var.okta_org_name}.${var.okta_base_url}/oauth2/v1/token"
    iss = var.okta_client_id
    sub = var.okta_client_id
    iat = floor(timestamp())  # JWT expects integer timestamps
    exp = floor(timeadd(timestamp(), "5m"))
    jti = uuid()
    # The 'kid' goes in the claims if needed, not in a separate header
    kid = var.okta_private_key_id
  })
}


# Use the JWT to get an access token
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
  ])}&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=${jwt_hashed_token.okta_assertion.token}"
}

locals {
  token_response = jsondecode(data.http.okta_token.response_body)
  access_token   = local.token_response.access_token
}

# Configure restapi provider with OAuth token
provider "restapi" {
  uri                  = "https://${var.okta_org_name}.${var.okta_base_url}"
  write_returns_object = true
  headers = {
    Authorization  = "Bearer ${local.access_token}"
    Accept        = "application/json"
    Content-Type  = "application/json"
  }
}
