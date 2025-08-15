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

# Password Policy Outputs
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

# Profile Enrollment Policy Outputs
output "profile_enrollment_policy_id" {
  description = "The ID of the profile enrollment policy"
  value       = okta_policy_profile_enrollment.pw_policy.id
}

output "profile_enrollment_policy_name" {
  description = "The name of the profile enrollment policy"
  value       = okta_policy_profile_enrollment.pw_policy.name
}

output "profile_enrollment_policy_status" {
  description = "The status of the profile enrollment policy"
  value       = okta_policy_profile_enrollment.pw_policy.status
}

# Summary Outputs for Quick Reference
output "policy_summary" {
  description = "Summary of all configured policies"
  value = {
    password_policy = {
      id                = okta_policy_password.pw_policy.id
      name              = okta_policy_password.pw_policy.name
      min_length        = okta_policy_password.pw_policy.password_min_length
      lockout_attempts  = okta_policy_password.pw_policy.password_max_lockout_attempts
      auto_unlock_mins  = okta_policy_password.pw_policy.password_auto_unlock_minutes
      dictionary_check  = okta_policy_password.pw_policy.password_dictionary_lookup
    }
    enrollment_policy = {
      id     = okta_policy_profile_enrollment.pw_policy.id
      name   = okta_policy_profile_enrollment.pw_policy.name
      status = okta_policy_profile_enrollment.pw_policy.status
    }
  }
}

output "authenticator_summary" {
  description = "Summary of all configured authenticators"
  value = {
    password = {
      id     = okta_authenticator.okta_pw.id
      name   = okta_authenticator.okta_pw.name
      status = okta_authenticator.okta_pw.status
    }
    okta_verify = {
      id     = okta_authenticator.okta_verify.id
      name   = okta_authenticator.okta_verify.name
      status = okta_authenticator.okta_verify.status
    }
  }
}
