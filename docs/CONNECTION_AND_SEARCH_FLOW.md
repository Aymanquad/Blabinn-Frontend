# Connection and Search Flow Documentation

## Overview

The Connection and Search system provides users with tools to discover new people, send friend requests, and manage their connections within the app. This document outlines the frontend implementation and user experience flow.

## Core Features

### 1. User Discovery
- **Connect Screen**: Main interface for finding new people
- **Search Functionality**: Search users by name, username, or interests
- **Filter System**: Customize search criteria (distance, language, age, interests)
- **Random Matching**: Queue-based system for discovering random connections

### 2. Friend Request Management
- **Send Requests**: Ability to send friend requests with optional messages
- **Incoming Requests**: Manage received friend requests
- **Outgoing Requests**: Track and manage sent requests
- **Friend List**: View and manage current friends

### 3. Connection States
- **Pending**: Request sent but awaiting response
- **Accepted**: Successfully connected as friends
- **Rejected**: Request declined
- **Cancelled**: Request cancelled by sender

## User Interface Components

### Connect Screen (`connect_screen.dart`)

#### Main Features
- **Welcome Interface**: Introduction to the connection system
- **Filter Management**: Set preferences for discovering people
- **Random Matching**: Start/stop matching process
- **Premium Features**: Access to advanced filtering options

#### User Flow
1. User opens Connect screen
2. Reviews current filter settings
3. Adjusts preferences if needed
4. Starts random matching process
5. Views matching progress
6. Receives match notifications

#### Filter Options
- **Distance**: Select preferred distance range (1-5, 5-10, 10-20, 20+ km)
- **Language**: Filter by preferred languages
- **Age Range**: Set minimum/maximum age preferences (Premium)
- **Interests**: Match based on shared interests (Premium)

### Friend Requests Screen (`friend_requests_screen.dart`)

#### Main Features
- **Tabbed Interface**: Separate tabs for incoming and outgoing requests
- **Request Cards**: Visual representation of each request
- **Action Buttons**: Accept, reject, or cancel requests
- **Profile Previews**: Quick view of user profiles

#### User Flow
1. User opens Friend Requests screen
2. Views incoming requests tab
3. Reviews sender profiles
4. Accepts or rejects requests
5. Switches to outgoing requests tab
6. Manages sent requests (cancel if needed)

#### Request Management
- **Accept Request**: Creates friendship connection
- **Reject Request**: Declines the request
- **Cancel Request**: Removes sent request
- **View Profile**: Opens detailed profile view

## API Integration

### Connection Services
The frontend uses `ApiService` to communicate with the backend:

#### Core Methods
- `sendFriendRequest()`: Send new friend request
- `acceptFriendRequest()`: Accept incoming request
- `rejectFriendRequest()`: Reject incoming request
- `cancelFriendRequest()`: Cancel sent request
- `getIncomingFriendRequests()`: Fetch incoming requests
- `getOutgoingFriendRequests()`: Fetch outgoing requests
- `getFriends()`: Get current friend list
- `removeFriend()`: Remove friend connection

#### Search Methods
- `searchProfiles()`: Search users with filters
- `getUserProfile()`: Get specific user profile
- `getConnectionStatus()`: Check connection status with user

## User Experience Flow

### Discovery to Connection
1. **Open Connect Screen**
   - User navigates to connection interface
   - Views current filter settings
   - Sees welcome message and instructions

2. **Set Preferences**
   - Opens filter dialog
   - Selects distance preferences
   - Chooses language preferences
   - Sets premium filters if available

3. **Start Matching**
   - Clicks "Start Matching" button
   - Enters matching mode with progress indicator
   - System searches for compatible users

4. **Receive Match**
   - System finds potential match
   - User receives match notification
   - Profile preview is displayed

5. **Send Friend Request**
   - User reviews match profile
   - Clicks "Send Request" button
   - Optional message can be added
   - Request is sent to matched user

### Request Management Flow
1. **Receive Notification**
   - User gets notification of new request
   - Notification badge appears on requests screen

2. **Review Request**
   - User opens Friend Requests screen
   - Reviews incoming request details
   - Views sender's profile information

3. **Make Decision**
   - User accepts or rejects request
   - System updates connection status
   - Confirmation message is shown

4. **Manage Friends**
   - Accepted connections appear in friend list
   - Users can chat or view profiles
   - Option to remove friends if needed

## Filter System

### Basic Filters (Free)
- **Distance Range**: Choose proximity preferences
- **Language**: Select preferred languages
- **Activity Status**: Filter by online/offline status

### Premium Filters
- **Age Range**: Detailed age preferences
- **Interests**: Match based on shared interests
- **Advanced Location**: More precise location filtering
- **Activity Patterns**: Match based on app usage patterns

## State Management

### Connection States
- **Idle**: No active matching process
- **Matching**: Actively searching for connections
- **Matched**: Found potential connection
- **Requesting**: Sending friend request
- **Pending**: Awaiting response to request

### Request States
- **Loading**: Fetching request data
- **Success**: Operations completed successfully
- **Error**: Failed operations with error messages
- **Empty**: No requests available

## Error Handling

### Common Errors
- **Network Issues**: Connection problems with backend
- **Authentication Errors**: Invalid or expired tokens
- **User Not Found**: Target user no longer exists
- **Duplicate Requests**: Attempting to send duplicate requests
- **Rate Limiting**: Too many requests in short time

### User Feedback
- **Error Messages**: Clear, actionable error descriptions
- **Retry Options**: Ability to retry failed operations
- **Loading States**: Visual feedback during operations
- **Success Confirmation**: Confirmation of successful actions

## Premium Features

### Enhanced Discovery
- **Advanced Filters**: More detailed search criteria
- **Priority Matching**: Higher priority in random matching
- **Extended Messages**: Longer friend request messages
- **Match Analytics**: Insights into connection success

### Visual Indicators
- **Premium Badges**: Indicate premium-only features
- **Upgrade Prompts**: Encourage premium subscriptions
- **Feature Previews**: Show locked premium features

## Performance Considerations

### Optimization Strategies
- **Lazy Loading**: Load data as needed
- **Caching**: Cache frequently accessed data
- **Pagination**: Limit result sets for performance
- **Debouncing**: Prevent excessive API calls

### User Experience
- **Loading States**: Show progress during operations
- **Offline Support**: Basic functionality when offline
- **Error Recovery**: Graceful handling of failures
- **Smooth Animations**: Enhance user interaction

## Future Enhancements

### Planned Features
- **Video Preview**: Short video introductions
- **Voice Messages**: Audio friend requests
- **Group Connections**: Connect with multiple users
- **Location Sharing**: Real-time location updates
- **Interest Matching**: AI-powered interest analysis

### Technical Improvements
- **Real-time Updates**: Live connection status
- **Background Sync**: Sync data in background
- **Offline Queue**: Queue operations for later sync
- **Performance Monitoring**: Track user experience metrics

This system provides an intuitive and engaging way for users to discover and connect with new people, while maintaining privacy and security standards. 