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


# Using terraform_data (modern replacement for null_resource)
resource "terraform_data" "okta_verify_methods" {
  triggers_replace = {
    authenticator_id = okta_authenticator.okta_verify.id
    # Use the actual settings string, not a hash
    settings = okta_authenticator.okta_verify.settings
  }

  provisioner "local-exec" {
    # Proper error handling and idempotency
    command = <<-EOT
      #!/bin/bash
      set -euo pipefail  # Exit on error, undefined vars, pipe failures
      
      # Configuration
      BASE_URL="https://${var.okta_org_name}.${var.okta_base_url}"
      AUTH_HEADER="Authorization: Bearer ${local.access_token}"
      AUTHENTICATOR_ID="${okta_authenticator.okta_verify.id}"
      
      # Function to check and activate a method
      activate_method() {
        local METHOD=$1
        local METHOD_NAME=$2
        
        echo "Checking $METHOD_NAME status..."
        
        # Get current status
        RESPONSE=$(curl -s -w "\n%%HTTP_CODE%%:" \
          -H "$AUTH_HEADER" \
          "$BASE_URL/api/v1/authenticators/$AUTHENTICATOR_ID/methods/$METHOD")
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1 | cut -d: -f1)
        BODY=$(echo "$RESPONSE" | sed '$d')
        
        # Handle different response codes
        if [ "$HTTP_CODE" = "404" ]; then
          echo "  $METHOD_NAME not available on this authenticator"
          return 0
        elif [ "$HTTP_CODE" != "200" ]; then
          echo "  Error checking $METHOD_NAME: HTTP $HTTP_CODE"
          echo "  Response: $BODY"
          return 1
        fi
        
        # Check if already active
        STATUS=$(echo "$BODY" | jq -r '.status // "UNKNOWN"')
        
        if [ "$STATUS" = "ACTIVE" ]; then
          echo "  ✓ $METHOD_NAME already active"
          return 0
        fi
        
        # Activate the method
        echo "  Activating $METHOD_NAME..."
        ACTIVATE_RESPONSE=$(curl -s -w "\n%%HTTP_CODE%%:" -X POST \
          -H "$AUTH_HEADER" \
          "$BASE_URL/api/v1/authenticators/$AUTHENTICATOR_ID/methods/$METHOD/lifecycle/activate")
        
        ACTIVATE_CODE=$(echo "$ACTIVATE_RESPONSE" | tail -n1 | cut -d: -f1)
        ACTIVATE_BODY=$(echo "$ACTIVATE_RESPONSE" | sed '$d')
        
        if [ "$ACTIVATE_CODE" = "200" ] || [ "$ACTIVATE_CODE" = "204" ]; then
          echo "  ✓ $METHOD_NAME activated successfully"
        else
          echo "  ✗ Failed to activate $METHOD_NAME: HTTP $ACTIVATE_CODE"
          echo "  Response: $ACTIVATE_BODY"
          return 1
        fi
      }
      
      # Activate both methods
      echo "Configuring Okta Verify methods for authenticator: $AUTHENTICATOR_ID"
      activate_method "push" "Push Notifications"
      activate_method "signed_nonce" "FastPass"
      echo "Configuration complete"
    EOT
    
    interpreter = ["bash", "-c"]
  }
  
  # Store the configuration state
  input = {
    authenticator_id = okta_authenticator.okta_verify.id
    timestamp        = timestamp()
    methods_enabled  = ["push", "signed_nonce"]
  }
}

resource "okta_policy_password" "pw_policy" {
  name                          = "Password Policy"
  status                        = "ACTIVE"
  description                   = "Password Policy"
  priority                      = 1
  auth_provider                 = "OKTA"
  
  # NIST 2025: Minimum 8 chars, recommended 15+
  password_min_length           = 15
  
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
  password_dictionary_lookup    = true
  
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
  password_unlock = "DENY"     # Can users self-unlock?
  
  # Network zones are OPTIONAL and rarely needed:
  network_connection = "ANYWHERE"  # Usually just leave this as ANYWHERE
}
resource "okta_policy_profile_enrollment" "example" {
  name   = "Enrollment Policy"
  status = "ACTIVE"
}


resource "okta_policy_mfa" "passwordless_requirement" {
  name            = "Passwordless Requirement"
  description     = ""
  status          = "ACTIVE"
  priority        = 1
  
 okta_email = {
    enroll = "REQUIRED"  # Andrew has this as REQUIRED
  }
  okta_verify = {
    enroll = "REQUIRED"
  }
  okta_password = {
    enroll = "REQUIRED"  # This works in Andrew's setup
  }
}