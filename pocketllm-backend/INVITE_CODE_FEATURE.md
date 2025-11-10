# Invite Code Feature

## Overview
This feature allows administrators to control whether new user signups require an invite code or not through an environment variable.

## Configuration

### Environment Variable
To control the invite code requirement, set the `INVITE_CODE` environment variable:

- `INVITE_CODE=True` (default): New signups require a valid invite code
- `INVITE_CODE=False`: New signups can proceed without an invite code

### Example .env Configuration
```env
# Require invite codes for signup (default behavior)
INVITE_CODE=True

# Allow signups without invite codes
INVITE_CODE=False
```

## Behavior

When `INVITE_CODE=False`:
1. Users can sign up without providing an invite code
2. If a user provides an invite code, it will still be validated
3. If a user has an approved waitlist application, they can still sign up
4. In development/test environments, the bypass still works as before

When `INVITE_CODE=True` (default):
1. Users must provide a valid invite code to sign up
2. Users with approved waitlist applications can still sign up
3. In development/test environments, the bypass still works as before

## Implementation Details

The feature was implemented by:
1. Adding the `invite_code_required` setting to the [Settings](file:///d:/Projects/pocketllm/pocketllm-backend/app/core/config.py#L12-L101) class
2. Modifying the [enforce_signup_policy](file:///d:/Projects/pocketllm/pocketllm-backend/app/services/referrals.py#L50-L70) method to check this setting
3. Maintaining backward compatibility with existing behavior

## Testing

The feature has been tested to ensure:
1. When `INVITE_CODE=False`, signups without invite codes succeed
2. When `INVITE_CODE=True`, signups without invite codes are rejected
3. Existing functionality (valid invite codes, waitlist approvals) continues to work
4. Development/test environment bypass still functions correctly