# User Profile Feature

**Overview:** Add a user profile page where users can view and edit their personal information.

## Task: Create Profile Data Model

**Category**: Backend
**Priority**: 1

Create the database schema and model classes for storing user profile information.

### Acceptance Criteria
- Create users table with fields: id, name, email, bio, avatar_url, created_at, updated_at
- Implement User model class with validation methods
- Email field must validate email format
- Bio field limited to 500 characters
- Test: Run `npm test -- user-model.test.js` and verify all tests pass
- Test: Database migration creates users table successfully

## Task: Implement Profile API Endpoints

**Category**: Backend
**Priority**: 2

Build REST API endpoints for profile operations.

### Acceptance Criteria
-GET /api/profile/:id returns user profile data
- PUT /api/profile/:id updates user profile (authenticated users only)
- Endpoint returns 404 if user not found
- Endpoint returns 403 if user tries to edit another user's profile
- Input validation rejects invalid email formats
- Test: Run `npm test -- profile-api.test.js` and verify all tests pass
- Test: Manual test with curl commands succeeds

## Task: Build Profile Page UI

**Category**: Frontend
**Priority**: 3

Create the user interface for viewing and editing profiles.

### Acceptance Criteria
-Display user name, email, bio, and avatar
- Show "Edit Profile" button for profile owner only
- Edit mode shows form with input fields
- Save button calls API and shows success message
- Cancel button reverts changes
- Form validation shows inline errors
- Test: Run `npm test -- profile-ui.test.js` and verify all tests pass
- Test: Open browser to /profile/1 and verify page renders correctly
