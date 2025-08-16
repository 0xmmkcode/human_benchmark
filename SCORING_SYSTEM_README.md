# Human Benchmark - Scoring System

This document explains the comprehensive scoring system integrated into your Human Benchmark application.

## 🎯 **Overview**

The scoring system tracks user performance across all games, stores scores in Firebase, and provides real-time leaderboards. It's designed to be:

- **Comprehensive**: Tracks all game types and individual attempts
- **Real-time**: Updates leaderboards instantly
- **Scalable**: Uses Firebase for cloud storage
- **User-friendly**: Shows personal progress and global rankings

## 🏗️ **Architecture**

### **Models**

#### **UserScore** (`lib/models/user_score.dart`)
- Tracks user's high scores across all games
- Maintains total games played per game type
- Records last played dates
- Calculates overall score (sum of all high scores)

#### **GameScore** (`lib/models/game_score.dart`)
- Individual game attempt records
- Stores game-specific data (rounds, timestamps, etc.)
- Links to user and game type
- Marks high score achievements

#### **GameType** (Enum)
- `reactionTime` - Reaction time in milliseconds
- `decisionRisk` - Decision risk score
- `personalityQuiz` - Personality quiz percentage
- `numberMemory` - Number memory sequence length
- `verbalMemory` - Verbal memory score
- `visualMemory` - Visual memory score
- `typingSpeed` - Words per minute
- `aimTrainer` - Aim accuracy in milliseconds
- `sequenceMemory` - Sequence memory length
- `chimpTest` - Chimp test score

### **Services**

#### **ScoreService** (`lib/services/score_service.dart`)
- **submitGameScore()** - Records new game attempts
- **getUserHighScore()** - Gets user's best score for a game
- **getUserScoreProfile()** - Gets complete user profile
- **getGameLeaderboard()** - Gets leaderboard for specific game
- **getOverallLeaderboard()** - Gets overall leaderboard
- **getUserRanking()** - Gets user's ranking in a game

## 🚀 **Usage Examples**

### **Submitting a Score**

```dart
// In your game after completion
await ScoreService.submitGameScore(
  gameType: GameType.reactionTime,
  score: 245, // milliseconds
  gameData: {
    'rounds': 5,
    'averageTime': 245,
    'bestTime': 180,
  },
);
```

### **Getting User's High Score**

```dart
final highScore = await ScoreService.getUserHighScore(GameType.reactionTime);
print('Your best reaction time: ${highScore}ms');
```

### **Displaying Leaderboard**

```dart
StreamBuilder<List<UserScore>>(
  stream: ScoreService.getGameLeaderboard(GameType.reactionTime),
  builder: (context, snapshot) {
    // Build your leaderboard UI
  },
)
```

## 🎮 **Game Integration**

### **Reaction Time Game**
- ✅ Already integrated
- Tracks reaction time in milliseconds
- Stores round counter and timestamps

### **Decision Risk Game**
- ⚠️ Needs integration
- Should track risk preference percentage
- Store decision times and choices

### **Personality Quiz**
- ⚠️ Needs integration
- Track completion percentage
- Store trait scores

### **Other Games**
- Add scoring calls in completion logic
- Use appropriate GameType enum
- Include relevant game data

## 📊 **Firebase Collections**

### **user_scores**
```json
{
  "userId": "user123",
  "userName": "John Doe",
  "highScores": {
    "reactionTime": 180,
    "decisionRisk": 75,
    "personalityQuiz": 85
  },
  "totalGamesPlayed": {
    "reactionTime": 25,
    "decisionRisk": 10,
    "personalityQuiz": 3
  },
  "lastPlayedAt": {
    "reactionTime": "2025-08-16T16:30:00Z",
    "decisionRisk": "2025-08-16T15:45:00Z"
  },
  "createdAt": "2025-08-16T10:00:00Z",
  "updatedAt": "2025-08-16T16:30:00Z"
}
```

### **game_scores**
```json
{
  "id": "1734360000000_user123_reactionTime",
  "userId": "user123",
  "userName": "John Doe",
  "gameType": "reactionTime",
  "score": 180,
  "gameData": {
    "rounds": 5,
    "averageTime": 245,
    "bestTime": 180
  },
  "playedAt": "2025-08-16T16:30:00Z",
  "isHighScore": true
}
```

## 🎨 **UI Components**

### **ScoreDisplay Widget**
- Shows user's current game score
- Displays overall statistics
- Lists recent high scores
- Links to leaderboard

### **ComprehensiveLeaderboardPage**
- Tabbed interface for all games
- Overall leaderboard (sum of all scores)
- Individual game leaderboards
- Real-time updates
- Beautiful ranking display

## 🔧 **Setup Requirements**

### **Firebase Configuration**
1. Ensure Firebase is initialized in your app
2. Firestore rules allow read/write access
3. Authentication is configured (optional, falls back to anonymous)

### **Dependencies**
```yaml
dependencies:
  cloud_firestore: ^latest
  firebase_auth: ^latest
  firebase_core: ^latest
```

## 📱 **User Experience Features**

### **Personal Progress**
- High scores for each game
- Total games played
- Progress tracking over time
- Achievement notifications

### **Competition**
- Global leaderboards
- Real-time rankings
- Friend comparisons
- Game-specific challenges

### **Analytics**
- Performance trends
- Game completion rates
- User engagement metrics
- Score distribution

## 🚀 **Future Enhancements**

### **Advanced Scoring**
- Weighted scoring based on difficulty
- Time-based score decay
- Bonus points for streaks
- Achievement badges

### **Social Features**
- Friend challenges
- Team competitions
- Score sharing
- Community events

### **Analytics Dashboard**
- Personal performance graphs
- Game comparison charts
- Progress milestones
- Improvement suggestions

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Scores not saving**
   - Check Firebase connection
   - Verify Firestore permissions
   - Check console for errors

2. **Leaderboard not updating**
   - Ensure real-time listeners are active
   - Check network connectivity
   - Verify data structure

3. **Performance issues**
   - Limit leaderboard queries (use pagination)
   - Cache frequently accessed data
   - Use offline persistence

### **Debug Commands**

```dart
// Check if Firebase is connected
print('Firebase apps: ${Firebase.apps.length}');

// Verify user authentication
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');

// Test score submission
try {
  await ScoreService.submitGameScore(
    gameType: GameType.reactionTime,
    score: 100,
  );
  print('Score submitted successfully');
} catch (e) {
  print('Score submission failed: $e');
}
```

## 📚 **API Reference**

### **ScoreService Methods**

| Method | Description | Returns |
|--------|-------------|---------|
| `submitGameScore()` | Submit new game score | `Future<void>` |
| `getUserHighScore()` | Get user's best score | `Future<int>` |
| `getUserScoreProfile()` | Get complete profile | `Future<UserScore?>` |
| `getGameLeaderboard()` | Get game leaderboard | `Stream<List<UserScore>>` |
| `getOverallLeaderboard()` | Get overall leaderboard | `Stream<List<UserScore>>` |
| `getUserRanking()` | Get user's rank | `Future<int>` |

### **UserScore Methods**

| Method | Description | Returns |
|--------|-------------|---------|
| `getHighScore(GameType)` | Get score for specific game | `int` |
| `getTotalGames(GameType)` | Get games played for game | `int` |
| `getLastPlayed(GameType)` | Get last played date | `DateTime?` |
| `overallScore` | Sum of all high scores | `int` |
| `totalGamesPlayedOverall` | Total games across all | `int` |

## 🤝 **Contributing**

To add scoring to a new game:

1. **Update GameType enum** with new game type
2. **Add scoring call** in game completion logic
3. **Update UI components** to display new game scores
4. **Test integration** with Firebase
5. **Update documentation** with new game details

## 📄 **License**

This scoring system is part of the Human Benchmark application and follows the same license terms.
