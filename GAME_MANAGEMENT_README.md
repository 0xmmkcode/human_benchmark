# Game Management System

This system allows administrators to control game visibility and access across the Human Benchmark platform.

## Features

### Game Status Control
- **Active**: Game is visible in menu and fully playable
- **Hidden**: Game is hidden from menu but accessible via direct URL
- **Blocked**: Game is completely inaccessible
- **Maintenance**: Game is temporarily unavailable with optional end date

### Admin Controls
- Set game status with optional reason
- Schedule maintenance periods
- Bulk game management
- Real-time status updates

## Setup

### 1. Admin User Setup
To use game management, a user must have admin privileges. Add the `isAdmin: true` field to their user document in Firestore:

```javascript
// In Firestore: users/{userId}
{
  "isAdmin": true,
  "email": "admin@example.com",
  // ... other user fields
}
```

### 2. Initialize Game Management
The system will automatically create game management records when an admin first accesses the management page. Default games include:

- Reaction Time
- Number Memory
- Decision Making
- Personality Quiz
- Aim Trainer
- Verbal Memory
- Visual Memory
- Typing Speed
- Sequence Memory
- Chimp Test

## Usage

### Admin Game Management Page
Navigate to `/admin/game-management` to access the admin interface.

#### Managing Individual Games
1. Click "Manage" on any game card
2. Set the desired status
3. Add optional reason for status change
4. Set maintenance end date if applicable
5. Click "Update"

#### Status Descriptions
- **Active**: Users can see and play the game normally
- **Hidden**: Game won't appear in menus but direct links still work
- **Blocked**: Game is completely inaccessible with error message
- **Maintenance**: Game shows maintenance message with optional end date

### Integration in Code

#### Game Access Guard
Wrap game pages with the `GameAccessGuard` widget:

```dart
GameAccessGuard(
  gameId: 'reaction_time',
  child: ReactionTimePage(),
)
```

#### Game Menu
Use the `GameMenu` widget to display only visible games:

```dart
GameMenu(
  onGameSelected: (gameId) => _navigateToGame(gameId),
  selectedGameId: _currentGameId,
  compact: false,
)
```

#### Service Methods
```dart
// Check if game is accessible
bool accessible = await GameManagementService.isGameAccessible('reaction_time');

// Check if game should be visible in menu
bool visible = await GameManagementService.isGameVisible('reaction_time');

// Get game status info
Map<String, dynamic>? statusInfo = await GameManagementService.getGameStatusInfo('reaction_time');
```

## Firestore Structure

### Collection: `game_management`
```javascript
{
  "gameId": "reaction_time",
  "gameName": "Reaction Time",
  "status": "active", // active, hidden, blocked, maintenance
  "reason": "Optional reason for status change",
  "blockedUntil": "2024-01-01T00:00:00Z", // Optional timestamp
  "updatedAt": "2024-01-01T00:00:00Z",
  "updatedBy": "admin_user_id"
}
```

### Collection: `users`
```javascript
{
  "uid": "user_id",
  "isAdmin": true, // Required for admin access
  "email": "user@example.com",
  // ... other user fields
}
```

## Security Rules

Ensure your Firestore security rules allow only admins to modify game management:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only admins can read/write game management
    match /game_management/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Users can read their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Best Practices

### 1. Status Management
- Use "Hidden" for games you want to temporarily remove from menus
- Use "Blocked" for games that should be completely inaccessible
- Use "Maintenance" for temporary outages with clear end dates

### 2. User Communication
- Always provide clear reasons for status changes
- Set realistic maintenance end dates
- Consider user impact when blocking popular games

### 3. Monitoring
- Regularly review game statuses
- Monitor user feedback about blocked games
- Keep maintenance periods as short as possible

## Troubleshooting

### Common Issues

#### Admin Access Denied
- Ensure user document has `isAdmin: true`
- Check Firestore security rules
- Verify user is authenticated

#### Games Not Loading
- Check if game management records exist
- Verify Firestore permissions
- Check console for errors

#### Status Changes Not Taking Effect
- Refresh the page after status changes
- Check if changes were saved to Firestore
- Verify game access guards are properly implemented

### Debug Mode
Enable debug logging by checking the browser console for detailed error messages from the game management service.

## Support

For technical support or questions about the game management system, contact the development team or check the project documentation.
