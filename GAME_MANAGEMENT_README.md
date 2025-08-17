# 🎮 Game Management System

## Overview

The Game Management System allows administrators to enable or disable games on the Human Benchmark website. When a game is disabled, users cannot access it and will be redirected to a "Game Not Available" page.

## 🏗️ Architecture

### Components

1. **GameManagement Model** (`lib/models/game_management.dart`)
   - Defines the structure for game settings
   - Includes predefined list of all available games
   - Tracks enable/disable status, metadata, and audit info

2. **GameManagementService** (`lib/services/game_management_service.dart`)
   - Manages game enable/disable operations
   - Handles Firestore operations for game settings
   - Provides methods for bulk updates and resets

3. **RouteProtectionService** (`lib/services/route_protection_service.dart`)
   - Protects game routes from unauthorized access
   - Redirects disabled games to appropriate pages
   - Integrates with navigation and routing

4. **AdminGameManagementPage** (`lib/web/pages/admin_game_management_page.dart`)
   - Admin interface for managing game states
   - Shows statistics and allows bulk operations
   - Provides visual feedback for changes

5. **GameNotAvailablePage** (`lib/web/pages/game_not_available_page.dart`)
   - User-friendly page when games are disabled
   - Shows available games and navigation options
   - Explains why games might be unavailable

6. **ProtectedGameRoute** (`lib/web/components/protected_game_route.dart`)
   - Wrapper component for game routes
   - Checks game status before rendering
   - Redirects to fallback page if disabled

## 🔐 Security

### Firestore Rules

```javascript
// Game management collection - only admins can modify
match /game_management/{gameId} {
  // Anyone can read game status (needed for route protection)
  allow read: if true;
  
  // Only admins can create, update, or delete game settings
  allow create, update, delete: if request.auth != null && 
    exists(/databases/$(database)/documents/admin_roles/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/admin_roles/$(request.auth.uid)).data.isAdmin == true;
}
```

### Access Control

- **Read Access**: Public (needed for route protection)
- **Write Access**: Admin only (create, update, delete)
- **Admin Verification**: Checks `admin_roles` collection

## 🚀 Setup and Deployment

### 1. Deploy Firestore Rules and Indexes

```bash
# Make script executable
chmod +x deploy_game_management.sh

# Deploy everything
./deploy_game_management.sh
```

### 2. Initialize Game Management

The system automatically initializes with default games when first accessed:
- All games start as enabled
- Default games include: Reaction Time, Number Memory, Decision Making, etc.
- Games can be individually enabled/disabled

### 3. Access Admin Panel

1. Navigate to the web app
2. Sign in as an admin user
3. Access "Game Management" from the sidebar
4. Configure game states as needed

## 📱 Usage

### For Administrators

1. **Access Game Management**
   - Navigate to `/app/admin-game-management`
   - Only visible to admin users

2. **Enable/Disable Games**
   - Toggle individual game switches
   - Save changes in bulk
   - Reset to default settings

3. **Monitor Changes**
   - View enabled/disabled game counts
   - See modification history
   - Track who made changes

### For Users

1. **Accessing Games**
   - Games automatically check if enabled
   - Disabled games redirect to "Game Not Available" page
   - Available games function normally

2. **Game Not Available Page**
   - Clear explanation of why game is unavailable
   - Links to available games
   - Navigation back to dashboard

## 🔄 Route Protection

### How It Works

1. **Route Wrapping**: All game routes are wrapped with `ProtectedGameRoute`
2. **Status Check**: Component checks if game is enabled via `GameManagementService`
3. **Complete Blocking**: Disabled games are completely inaccessible
4. **No Fallback Pages**: Users are blocked from accessing disabled games

### Real-Time Updates

The system provides **immediate menu hiding** for disabled games:

1. **Web Sidebar**: Uses `StreamBuilder` to listen for real-time game status changes
2. **Mobile Navigation**: Bottom navigation bar updates instantly when games are disabled
3. **Dashboard Filtering**: Game statistics automatically filter out disabled games
4. **No Page Refresh**: Changes take effect immediately without requiring app restart
5. **Complete Hiding**: Disabled games disappear completely from all navigation

### Protected Routes

- `/app/reaction` → Reaction Time Game
- `/app/number-memory` → Number Memory Game
- `/app/decision` → Decision Making Game
- `/app/personality` → Personality Quiz Game

### Access Control

- **Enabled Games**: Fully accessible with normal functionality
- **Disabled Games**: Completely hidden from navigation and inaccessible
- **No Fallback**: Users cannot access disabled games at all
- **Immediate Effect**: Changes take effect instantly across all platforms

## 📊 Database Schema

### Game Management Collection

```javascript
{
  "gameId": "reaction_time",
  "gameName": "Reaction Time",
  "gameType": "reaction_time",
  "isEnabled": true,
  "description": "Test your reflexes and reaction speed",
  "icon": "timer",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "updatedBy": "admin_user_id"
}
```

### Indexes

```javascript
{
  "collectionGroup": "game_management",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "isEnabled", "order": "ASCENDING"},
    {"fieldPath": "gameType", "order": "ASCENDING"}
  ]
}
```

## 🛠️ Development

### Adding New Games

1. **Update Model**: Add to `GameManagement.defaultGames`
2. **Update Routes**: Add to main.dart with protection
3. **Update Navigation**: Add to sidebar if needed
4. **Update Icons**: Add to `WebUtils.getIconFromString`

### Testing

1. **Enable/Disable Games**: Test admin interface
2. **Route Protection**: Verify disabled games redirect
3. **User Experience**: Test from non-admin perspective
4. **Edge Cases**: Test with network errors, invalid states

## 🚨 Troubleshooting

### Common Issues

1. **Games Not Loading**
   - Check Firestore rules deployment
   - Verify admin role setup
   - Check console for errors

2. **Route Protection Not Working**
   - Ensure `ProtectedGameRoute` wraps game components
   - Check `GameManagementService` connectivity
   - Verify game IDs match between service and routes

3. **Admin Access Denied**
   - Verify user has admin role in `admin_roles` collection
   - Check Firestore rules for admin_roles
   - Ensure proper authentication

### Debug Commands

```bash
# Check Firestore rules
firebase firestore:rules:get

# Check indexes
firebase firestore:indexes

# View logs
firebase functions:log
```

## 🔮 Future Enhancements

1. **Scheduled Maintenance**: Automatically disable games during maintenance windows
2. **A/B Testing**: Enable/disable games for specific user segments
3. **Analytics**: Track game usage and availability metrics
4. **Notifications**: Alert users when games become available again
5. **Mobile Support**: Extend game management to mobile app

## 📚 Related Files

- `lib/models/game_management.dart` - Data model
- `lib/services/game_management_service.dart` - Business logic
- `lib/services/route_protection_service.dart` - Route protection
- `lib/web/pages/admin_game_management_page.dart` - Admin UI
- `lib/web/pages/game_not_available_page.dart` - User fallback
- `lib/web/components/protected_game_route.dart` - Route wrapper
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Database indexes
- `deploy_game_management.sh` - Deployment script

## 🤝 Support

For issues or questions about the Game Management System:

1. Check this documentation
2. Review Firestore rules and indexes
3. Check browser console for errors
4. Verify admin permissions
5. Test with different user roles
