# Data Migration Guide - Human Benchmark App

## Overview

This document describes the migration from the legacy data structure to a new consolidated user profile system that stores all game statistics within each user's document in the `users` collection.

## New Data Structure

### User Profile Document (`users/{uid}`)

```json
{
  "uid": "user_id_here",
  "email": "user@example.com",
  "displayName": "User Name",
  "photoURL": "https://...",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  
  "gameStats": {
    "reactionTime": {
      "highScore": 150,
      "totalGames": 25,
      "averageScore": 180.5,
      "lastPlayed": "2024-01-01T00:00:00Z",
      "firstPlayed": "2024-01-01T00:00:00Z"
    },
    "numberMemory": {
      "highScore": 8,
      "totalGames": 15,
      "averageScore": 6.2,
      "lastPlayed": "2024-01-01T00:00:00Z",
      "firstPlayed": "2024-01-01T00:00:00Z"
    }
  },
  
  "recentScores": {
    "reactionTime": [
      {
        "id": "score_id",
        "userId": "user_id",
        "gameType": "reactionTime",
        "score": 150,
        "gameData": {...},
        "playedAt": "2024-01-01T00:00:00Z",
        "isHighScore": true
      }
    ]
  },
  
  "totalGamesPlayed": 40,
  "overallScore": 158,
  "lastGamePlayed": "2024-01-01T00:00:00Z",
  
  "migrationCompleted": true,
  "migratedAt": "2024-01-01T00:00:00Z",
  "migratedFrom": "legacy_user_scores"
}
```

### Game Stats Structure

Each game type has its own stats object:

```json
{
  "highScore": 150,
  "totalGames": 25,
  "averageScore": 180.5,
  "lastPlayed": "2024-01-01T00:00:00Z",
  "firstPlayed": "2024-01-01T00:00:00Z"
}
```

## Legacy Data Structure (Being Replaced)

### User Scores Collection (`user_scores/{uid}`)
- High scores per game type
- Total games played per game type
- Last played dates per game type

### Game Scores Collection (`game_scores`)
- Individual game score records
- Game-specific data
- Timestamps and metadata

## Benefits of New Structure

1. **Consolidated Data**: All user information in one document
2. **Better Performance**: Fewer collection reads for user data
3. **Easier Queries**: Single document contains all user stats
4. **Atomic Updates**: All stats updated in one transaction
5. **Better Scalability**: Reduced collection overhead

## Migration Process

### Automatic Migration

The app automatically migrates user data when:
- A user submits a new score
- User profile is accessed for the first time
- Admin triggers migration

### Manual Migration

Admins can trigger migration through the Admin Migration page:

1. Navigate to `/app/admin-migration`
2. Click "Migrate All Users" to migrate all existing users
3. Click "Migrate Current User" to migrate just the logged-in user
4. Monitor progress and status

### Migration Steps

1. **Data Extraction**: Read from legacy collections
2. **Data Transformation**: Convert to new structure
3. **Profile Creation**: Create new user profile document
4. **Data Validation**: Ensure all data is preserved
5. **Migration Marking**: Mark migration as complete

## Implementation Details

### New Services

- **UserProfileService**: Main service for user profile operations
- **MigrationService**: Handles data migration from legacy structure

### Backward Compatibility

The app maintains backward compatibility by:
- Trying new service first
- Falling back to legacy methods if needed
- Gradual migration of users
- No breaking changes to existing functionality

### Data Preservation

All existing data is preserved during migration:
- High scores
- Total games played
- Game history (limited to recent 10 per game type)
- User metadata

## Firestore Security Rules

### Users Collection

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && resource.data.migrationCompleted == true;
    }
  }
}
```

### Legacy Collections (Read-only during migration)

```javascript
match /user_scores/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Read-only during migration
}

match /game_scores/{scoreId} {
  allow read: if request.auth != null && resource.data.userId == request.auth.uid;
  allow write: if false; // Read-only during migration
}
```

## Testing Migration

### Before Migration

1. **Backup Data**: Ensure Firestore data is backed up
2. **Test Environment**: Test migration in development first
3. **User Notification**: Inform users about upcoming changes

### During Migration

1. **Monitor Progress**: Use admin page to track migration
2. **Error Handling**: Check logs for any migration failures
3. **Data Validation**: Verify migrated data integrity

### After Migration

1. **Verify Data**: Confirm all user data is accessible
2. **Performance Testing**: Ensure new structure performs well
3. **Cleanup**: Remove legacy collections (optional)

## Rollback Plan

If issues arise during migration:

1. **Stop Migration**: Disable automatic migration
2. **Revert Code**: Roll back to previous version
3. **Data Recovery**: Use backup to restore legacy structure
4. **Investigation**: Identify and fix migration issues

## Monitoring and Maintenance

### Migration Status

- Track migration progress
- Monitor error rates
- Validate data integrity
- Performance metrics

### Ongoing Operations

- New users automatically use new structure
- Legacy data remains accessible during transition
- Gradual cleanup of old collections
- Performance optimization

## Troubleshooting

### Common Issues

1. **Migration Failures**: Check user authentication and permissions
2. **Data Loss**: Verify backup and migration logs
3. **Performance Issues**: Monitor Firestore usage and quotas
4. **Authentication Errors**: Ensure proper Firebase setup

### Debug Information

- Migration logs in admin page
- Firestore console for data inspection
- App logs for detailed error information
- Migration status tracking

## Future Enhancements

1. **Batch Migration**: Process multiple users simultaneously
2. **Incremental Updates**: Migrate only changed data
3. **Data Analytics**: Enhanced reporting and insights
4. **Performance Optimization**: Further query optimization

## Support

For migration support:
1. Check migration logs in admin page
2. Review Firestore console for data issues
3. Check app logs for error details
4. Contact development team for complex issues

---

**Note**: This migration is designed to be safe and non-destructive. All existing data is preserved and the app maintains backward compatibility during the transition period.
