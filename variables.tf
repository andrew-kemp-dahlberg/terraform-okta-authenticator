variable "okta_org_name" {
  description = "Okta organization name (e.g., dev-123456)"
  type        = string
}

variable "okta_base_url" {
  description = "Okta base URL (okta.com or oktapreview.com)"
  type        = string
  default     = "okta.com"
}

variable "okta_client_id" {
  description = "OAuth2 client ID for Okta provider"
  type        = string
}

variable "okta_private_key_id" {
  description = "Private key ID for OAuth2 authentication"
  type        = string
}

variable "okta_private_key" {
  description = "Private key for OAuth2 authentication"
  type        = string
  sensitive   = true
}