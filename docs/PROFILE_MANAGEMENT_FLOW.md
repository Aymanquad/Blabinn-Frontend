# Profile Management Flow

## Overview
The Profile Management system allows users to create, view, update, and delete their personal profiles within the Blabbin app. This document explains the complete flow from a user's perspective.

## User Journey

### 1. First Time Access
- User signs in with Google/Apple/Guest account
- User navigates to Profile section
- System shows basic Firebase authentication information (display name, email, photo)
- User sees "Manage Profile" button to create a detailed profile

### 2. Creating a Profile
- User clicks "Manage Profile" button
- System opens Profile Management screen
- User sees empty form with all profile fields
- User can click "Get My Profile" to check if they already have a profile
- User fills out the form with their information:
  - Display Name (required)
  - Username (required, checked for availability in real-time)
  - Bio (optional, up to 500 characters)
  - Profile Picture (optional, can upload image)
  - Photo Gallery (optional, up to 5 images)
  - Gender (dropdown selection)
  - Age (number input, must be 13-120)
  - Interests (can add multiple interests as chips)
- User clicks "Create Profile" button
- System validates all fields
- System saves profile to backend database
- User sees success message

### 3. Viewing Profile
- User navigates to Profile section
- System displays:
  - Profile picture (or default icon if none)
  - Display name
  - Email address
  - Account status (Guest or Registered)
  - Settings options including "Manage Profile"

### 4. Updating Profile
- User clicks "Manage Profile" from Profile screen
- System opens Profile Management screen
- User clicks "Get My Profile" to load existing data
- Form automatically fills with current profile information
- User can modify any field:
  - Change display name
  - Update username (availability checked)
  - Edit bio
  - Upload new profile picture
  - Add/remove gallery images
  - Change gender selection
  - Update age
  - Add/remove interests
- User clicks "Update Profile" button
- System validates changes
- System saves updated profile to backend
- User sees success confirmation

### 5. Deleting Profile
- User clicks "Manage Profile" from Profile screen
- User clicks "Delete Profile" button (red button)
- System shows confirmation dialog
- User confirms deletion
- System removes profile from backend database
- User sees success message
- Form clears and returns to "create profile" state

## Key Features

### Real-Time Username Checking
- As user types username, system checks availability
- Shows loading spinner while checking
- Displays checkmark for available usernames
- Shows error message for taken usernames
- Prevents form submission with invalid usernames

### Image Upload System
- Users can upload profile pictures
- Users can add up to 5 gallery images
- Images are processed and stored securely
- Preview thumbnails shown after selection
- Remove functionality for unwanted images

### Interest Management
- Users can add interests by typing and pressing enter
- Interests appear as removable chips
- Maximum of 20 interests allowed
- Each interest limited to 50 characters
- Click to remove unwanted interests

### Form Validation
- Display name: Required, max 50 characters
- Username: Required, 3-30 characters, alphanumeric + underscore
- Bio: Optional, max 500 characters
- Age: Optional, must be 13-120 if provided
- Real-time validation with helpful error messages

## Button Functions

### "Get My Profile" Button
- Fetches current profile data from backend
- Populates form fields with existing information
- Useful for refreshing data or starting edits
- Shows if profile exists or needs to be created

### "Create Profile" Button
- Appears when no profile exists
- Validates all form fields
- Sends new profile data to backend
- Uploads profile picture if selected
- Changes to "Update Profile" after successful creation

### "Update Profile" Button
- Appears when profile already exists
- Validates modified fields
- Sends updated data to backend
- Uploads new images if selected
- Preserves existing data not being changed

### "Delete Profile" Button
- Permanently removes profile from system
- Shows confirmation dialog for safety
- Clears all form fields after deletion
- Returns user to "create profile" state

## Error Handling

### Common Error Scenarios
- **No Internet Connection**: Shows network error message
- **Username Taken**: Prevents submission with clear error
- **Invalid Age**: Shows validation error for age outside 13-120 range
- **Server Error**: Shows generic error message with retry option
- **Authentication Error**: Redirects to login if session expired

### Success Feedback
- **Profile Created**: Green success message confirmation
- **Profile Updated**: Confirmation with updated information
- **Profile Deleted**: Success message with cleared form
- **Username Available**: Green checkmark indicator

## Data Persistence

### What Gets Saved
- All profile information is stored in the backend database
- Profile pictures are uploaded to secure storage
- Gallery images are stored with user account
- Interests are saved as a list with the profile

### What Persists Between Sessions
- Profile data remains available after app restart
- Profile pictures and gallery images stay accessible
- Username reservation is maintained
- Form remembers last saved state

## Navigation Flow

1. **Main App** → **Profile Section** → **Manage Profile** → **Profile Management Screen**
2. **Profile Management Screen** → **Back Button** → **Profile Section**
3. **Profile Section** → **Logout** → **Login Screen**

## Security & Privacy

### Data Protection
- All profile data is secured with Firebase authentication
- Only authenticated users can access their own profile
- Profile pictures are stored securely
- Username availability checking prevents conflicts

### User Control
- Users own their profile data completely
- Can update any information at any time
- Can delete profile entirely if desired
- No data is shared without explicit permission

## Tips for Users

### Best Practices
- Use a unique, memorable username
- Keep bio concise but descriptive
- Upload a clear profile picture
- Add interests that represent you accurately
- Update profile regularly to keep it current

### Troubleshooting
- If username shows as taken, try variations
- If images won't upload, check file size and format
- If form won't save, check internet connection
- Use "Get My Profile" to refresh data if needed 