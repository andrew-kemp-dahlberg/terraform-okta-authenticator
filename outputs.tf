# outputs.tf

# Password Authenticator Outputs
output "password_authenticator_id" {
  description = "The ID of the Okta Password authenticator"
  value       = okta_authenticator.okta_pw.id
}

output "password_authenticator_status" {
  description = "The status of the Okta Password authenticator"
  value       = okta_authenticator.okta_pw.status
}

# Okta Verify Authenticator Outputs
output "okta_verify_authenticator_id" {
  description = "The ID of the Okta Verify authenticator"
  value       = okta_authenticator.okta_verify.id
}

output "okta_verify_authenticator_status" {
  description = "The status of the Okta Verify authenticator"
  value       = okta_authenticator.okta_verify.status
}

output "okta_verify_authenticator_settings" {
  description = "The settings for Okta Verify authenticator"
  value       = okta_authenticator.okta_verify.settings
  sensitive   = true
}

output "password_policy_id" {
  description = "The ID of the password policy"
  value       = okta_policy_password.pw_policy.id
}

output "password_policy_name" {
  description = "The name of the password policy"
  value       = okta_policy_password.pw_policy.name
}

output "password_policy_status" {
  description = "The status of the password policy"
  value       = okta_policy_password.pw_policy.status
}

output "password_policy_priority" {
  description = "The priority of the password policy"
  value       = okta_policy_password.pw_policy.priority
}

output "password_policy_min_length" {
  description = "Minimum password length requirement"
  value       = okta_policy_password.pw_policy.password_min_length
}

output "password_policy_lockout_attempts" {
  description = "Number of failed attempts before account lockout"
  value       = okta_policy_password.pw_policy.password_max_lockout_attempts
}

output "password_policy_auto_unlock_minutes" {
  description = "Minutes before locked account auto-unlocks"
  value       = okta_policy_password.pw_policy.password_auto_unlock_minutes
}

output "token_response_debug" {
  value = local.token_response
  sensitive = false  # Temporarily set to false for debugging
}

output "token_response_keys" {
  value = keys(local.token_response)
}

output "oauth_error" {
  value = local.error_message
}

output "token_response_debug" {
  value = local.token_response
  sensitive = false  # Temporarily for debugging
}