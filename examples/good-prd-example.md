# Email Validation Feature

**Overview:** Add email validation to the user registration form to prevent invalid email addresses and improve data quality.

**Project Directory:** /Users/paul.lovvik/AI/Claude/ralph/examples

## Task: Implement Backend Email Validation

**Category**: Backend
**Priority**: 1

Add server-side email validation using a robust validation library to ensure all email addresses meet RFC 5322 standards.

### Acceptance Criteria
-Install and configure `validator` npm package
- Create validateEmail() function that checks format and rejects common typos (missing @, .com, etc.)
- Function returns validation result object with isValid boolean and error message
- Validation rejects: empty strings, missing @ symbol, missing domain, invalid characters
- Validation accepts: standard formats (user@domain.com), subdomains (user@mail.domain.com), plus addressing (user+tag@domain.com)
- Add validation to POST /api/register endpoint before saving user
- Return 400 status with clear error message if email invalid
- Test: Run `npm test -- email-validation.test.js` and verify all 15 test cases pass
- Test: Use curl to POST invalid email to /api/register and verify 400 response with error message
- Test: Use curl to POST valid email and verify registration succeeds

## Task: Add Frontend Real-Time Email Validation

**Category**: Frontend
**Priority**: 2

Implement client-side email validation with real-time feedback as the user types in the registration form.

### Acceptance Criteria
-Add validation to email input field in RegistrationForm component
- Show inline error message below email field when format is invalid
- Display green checkmark icon when email is valid
- Validation triggers on blur and after 500ms of typing inactivity (debounced)
- Error message specifies the problem (e.g., "Email must include @" or "Invalid domain format")
- Disable submit button when email is invalid
- Clear error message when user focuses on field to edit
- Test: Run `npm test -- registration-form.test.js` and verify validation tests pass
- Test: Open browser to /register and type invalid email - verify error appears
- Test: Type valid email - verify checkmark appears and submit button enables

## Task: Add Email Format Documentation

**Category**: Documentation
**Priority**: 3

Document the email validation rules and provide examples for developers and users.

### Acceptance Criteria
-Add "Email Validation Rules" section to docs/validation.md
- List all validation rules with examples of valid and invalid formats
- Include code example showing how to use validateEmail() function
- Document the error messages users will see for each validation failure
- Add FAQ section covering common questions (why was my email rejected, etc.)
- Include link to RFC 5322 specification for reference
- Test: Review docs/validation.md and verify all rules documented
- Test: Try each documented invalid format and verify error message matches documentation
- Test: Ask colleague to review docs and confirm clarity
