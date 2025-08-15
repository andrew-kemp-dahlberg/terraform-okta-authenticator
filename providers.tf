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

provider "restapi" {
  uri                  = "https://${var.okta_org_name}.${var.okta_base_url}"
  write_returns_object = true
  headers = {
    Authorization = "SSWS ${var.okta_api_token}"
  }
}