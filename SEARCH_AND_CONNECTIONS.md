# Search and Friend Request System

This document describes the search functionality and friend request system implemented in the Blabbin application.

## Overview

The search and friend request system allows users to:

- Search for people by name, username, bio, or interests
- Send friend requests to other users
- Accept, reject, or cancel friend requests
- View their friends list
- Manage incoming and outgoing friend requests

## Backend Implementation

### Models

#### Connection Model (`blabbin-backend/src/models/Connection.js`)

- Represents friend requests and connections between users
- Supports different statuses: `pending`, `accepted`, `rejected`, `blocked`
- Includes message support for friend requests
- Tracks creation, acceptance, and rejection timestamps

### Services

#### Connection Service (`blabbin-backend/src/services/connectionService.js`)

- `sendFriendRequest(fromUserId, toUserId, requestData)` - Send a friend request
- `acceptFriendRequest(userId, connectionId)` - Accept a friend request
- `rejectFriendRequest(userId, connectionId)` - Reject a friend request
- `cancelFriendRequest(userId, connectionId)` - Cancel a sent friend request
- `getConnectionBetweenUsers(userId1, userId2)` - Get connection status between users
- `getIncomingFriendRequests(userId)` - Get incoming friend requests
- `getOutgoingFriendRequests(userId)` - Get outgoing friend requests
- `getFriends(userId)` - Get user's friends list
- `removeFriend(userId, friendUserId)` - Remove a friend

### Controllers

#### Connection Controller (`blabbin-backend/src/controllers/connectionController.js`)

- Handles all HTTP requests for connection management
- Includes proper error handling and validation
- Returns standardized API responses

### Routes

#### Connection Routes (`blabbin-backend/src/api/connectionRoutes.js`)

- `POST /api/connections/friend-request` - Send friend request
- `PUT /api/connections/friend-request/:connectionId/accept` - Accept friend request
- `PUT /api/connections/friend-request/:connectionId/reject` - Reject friend request
- `DELETE /api/connections/friend-request/:connectionId` - Cancel friend request
- `GET /api/connections/friend-requests/incoming` - Get incoming requests
- `GET /api/connections/friend-requests/outgoing` - Get outgoing requests
- `GET /api/connections/friends` - Get friends list
- `DELETE /api/connections/friends/:friendUserId` - Remove friend
- `GET /api/connections/status/:targetUserId` - Get connection status

## Frontend Implementation

### Screens

#### Search Screen (`lib/screens/search_screen.dart`)

- Search bar with real-time search functionality
- Displays search results with user cards
- Shows user profile pictures, names, usernames, bios, and interests
- "Connect" button to send friend requests
- Error handling and loading states
- Empty state when no results found

#### Friend Requests Screen (`lib/screens/friend_requests_screen.dart`)

- Tabbed interface for incoming and outgoing requests
- Accept/reject buttons for incoming requests
- Cancel button for outgoing requests
- Shows request messages and user information
- Pull-to-refresh functionality
- Empty states for no requests

### API Service

#### Updated API Service (`lib/services/api_service.dart`)

- `searchProfiles(searchParams)` - Search for users
- `sendFriendRequest(toUserId, {message?, type?})` - Send friend request
- `acceptFriendRequest(connectionId)` - Accept friend request
- `rejectFriendRequest(connectionId)` - Reject friend request
- `cancelFriendRequest(connectionId)` - Cancel friend request
- `getIncomingFriendRequests()` - Get incoming requests
- `getOutgoingFriendRequests()` - Get outgoing requests
- `getFriends()` - Get friends list
- `removeFriend(friendUserId)` - Remove friend
- `getConnectionStatus(targetUserId)` - Get connection status

### Navigation

#### Updated Home Screen (`lib/screens/home_screen.dart`)

- Added "Search People" section with prominent call-to-action
- Added "Friend Requests" section for quick access
- Both sections navigate to their respective screens

## Features

### Search Functionality

- **Real-time search**: Search as you type
- **Multiple search criteria**: Name, username, bio, interests
- **Rich user cards**: Profile pictures, names, usernames, bios, interests
- **Connect button**: One-click friend request sending
- **Error handling**: Proper error messages and retry functionality

### Friend Request System

- **Send requests**: With optional custom messages
- **Accept/Reject**: For incoming requests
- **Cancel**: For outgoing requests
- **Request tracking**: View all incoming and outgoing requests
- **Status management**: Track connection status between users

### User Experience

- **Modern UI**: Clean, professional design with gradients and shadows
- **Responsive design**: Works on different screen sizes
- **Loading states**: Proper loading indicators
- **Empty states**: Helpful messages when no data
- **Error handling**: User-friendly error messages
- **Pull-to-refresh**: For updating data

## API Endpoints

### Search

```
GET /api/profiles/search?searchTerm=john&limit=20
```

### Friend Requests

```
POST /api/connections/friend-request
{
  "toUserId": "user-id",
  "message": "Hey! Would you like to be friends?",
  "type": "friend"
}
```

### Accept/Reject Requests

```
PUT /api/connections/friend-request/:connectionId/accept
PUT /api/connections/friend-request/:connectionId/reject
DELETE /api/connections/friend-request/:connectionId
```

### Get Requests

```
GET /api/connections/friend-requests/incoming
GET /api/connections/friend-requests/outgoing
```

### Friends Management

```
GET /api/connections/friends
DELETE /api/connections/friends/:friendUserId
GET /api/connections/status/:targetUserId
```

## Testing

### Backend Testing

Run the connection endpoints test:

```bash
cd blabbin-backend
node test-connections.js
```

### Frontend Testing

1. Navigate to the home screen
2. Tap "Search People" to test search functionality
3. Tap "Friend Requests" to test request management
4. Try sending friend requests and accepting/rejecting them

## Security Features

- **Authentication required**: All connection endpoints require Firebase authentication
- **Rate limiting**: API endpoints are rate-limited to prevent abuse
- **Validation**: All inputs are validated before processing
- **Authorization**: Users can only manage their own requests
- **Error handling**: Proper error responses without exposing sensitive information

## Future Enhancements

- **Real-time notifications**: WebSocket notifications for friend requests
- **Friend suggestions**: AI-powered friend recommendations
- **Group connections**: Support for group chats and connections
- **Privacy settings**: Allow users to control who can send them requests
- **Blocking functionality**: Allow users to block others
- **Connection analytics**: Track connection patterns and statistics

## Technical Notes

- Uses Firebase Authentication for user management
- Implements proper error handling and logging
- Follows RESTful API design principles
- Uses Flutter's Material Design components
- Implements proper state management
- Includes comprehensive error handling and user feedback
