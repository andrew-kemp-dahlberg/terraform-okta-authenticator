#main.tf

resource "okta_authenticator" "okta_pw" {
  key                         = "okta_password"
  name                        = "Password"
  status                      = "ACTIVE"
}

resource "okta_authenticator" "okta_verify" {
  key    = "okta_verify"
  name   = "Okta Verify"
  status = "ACTIVE"

  settings = jsonencode({
    "allowedFor" : "any"
    "compliance" : {
      "fips" : "OPTIONAL"
    },
    "channelBinding" : {
      "style" : "NUMBER_CHALLENGE",
      "required" : "HIGH_RISK_ONLY"
    },
    "userVerification" : "REQUIRED",
    "enrollmentSecurityLevel" : "HIGH",
    "userVerificationMethods" : [
      "BIOMETRICS"
    ],
    "userVerification" : "REQUIRED"
  })
  lifecycle {
    create_before_destroy = true
  }
}


resource "okta_policy_password" "pw_policy" {
  name                          = "Password Policy"
  status                        = "ACTIVE"
  description                   = "Password Policy"
  priority                      = 1
  auth_provider                 = "OKTA"
  
  # NIST 2025: Minimum 8 chars, recommended 15+
  password_min_length           = 8
  
  # Character requirements - keeping flexibility per NIST
  password_min_lowercase        = 1
  password_min_uppercase        = 1
  password_min_number          = 1
  password_min_symbol          = 0  # Optional per NIST 2025
  
  # Username/name exclusions for security
  password_exclude_username     = true
  password_exclude_first_name   = true
  password_exclude_last_name    = true
  
  # NIST 2025: Check against compromised passwords
  password_dictionary_lookup    = false
  
  # NIST 2025: No periodic rotation unless compromised
  password_max_age_days        = 0  # No expiration
  password_expire_warn_days    = 0  # No warnings since no expiration
  
  # Password history to prevent reuse
  password_history_count       = 12  # Remember last 12 passwords
  password_min_age_minutes     = 60  # Prevent rapid changes (1 hour)
  
  # Account lockout settings for security
  password_max_lockout_attempts = 5   # Lock after 5 failed attempts
  password_auto_unlock_minutes  = 0  # Auto-unlock after 30 minutes
  password_show_lockout_failures = true
  password_lockout_notification_channels = ["EMAIL"]
  
  # Recovery options
  email_recovery              = "INACTIVE"  # Disable email recovery for security
  sms_recovery                = "INACTIVE"  # Enable for healthcare staff convenience
  call_recovery               = "INACTIVE"  # Disable voice calls for security
  
  # Security questions per NIST - better to disable
  question_recovery           = "INACTIVE"  # NIST recommends against
  question_min_length         = 4  # If enabled later
  
  # Don't unlock AD accounts automatically
  skip_unlock                 = false
}

resource "okta_policy_rule_password" "standard_users" {
  policy_id = okta_policy_password.pw_policy.id
  name      = "Standard Users"
  
  # These are what matter for password policies:
  password_change = "ALLOW"    # Can users change passwords?
  password_reset  = "ALLOW"    # Can users reset passwords?  
  password_unlock = "ALLOW"     # Can users self-unlock?
  
  # Network zones are OPTIONAL and rarely needed:
  network_connection = "ANYWHERE"  # Usually just leave this as ANYWHERE
}
resource "okta_policy_profile_enrollment" "this" {
  name   = "Enrollment Policy"
  status = "ACTIVE"
}


resource "okta_policy_mfa" "passwordless_requirement" {
  name            = "Passwordless Requirement"
  description     = ""
  status          = "ACTIVE"
  priority        = 1
  
 okta_email = {
    enroll = "ALLOWED"  
  }
  okta_verify = {
    enroll = "ALLOWED"
  }
  okta_password = {
    enroll = "REQUIRED"  
  }

}