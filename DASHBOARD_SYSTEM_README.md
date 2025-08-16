# Human Benchmark - Dashboard System

This document explains the comprehensive dashboard system that shows all players and their scores across all games.

## 🎯 **Overview**

The dashboard system provides a complete overview of:
- **All players** and their performance across all games
- **Real-time statistics** for each game type
- **Player rankings** and leaderboards
- **Recent activity** and achievements
- **Search and filtering** capabilities

## 🏗️ **Architecture**

### **DashboardService** (`lib/services/dashboard_service.dart`)
- **getDashboardOverview()** - Gets overall dashboard statistics
- **getAllPlayers()** - Gets all players with sorting and filtering
- **getGameLeaderboard()** - Gets leaderboard for specific games
- **searchPlayers()** - Searches players by name/ID
- **getPlayerDetails()** - Gets detailed player information

### **Dashboard Models**
- **DashboardOverview** - Overall statistics and top performers
- **PlayerDashboardData** - Player summary for dashboard display
- **PlayerDetailData** - Detailed player information
- **RecentActivity** - Recent game achievements
- **GameStatistics** - Game-specific statistics

## 📱 **Mobile Dashboard** (`lib/screens/dashboard_page.dart`)

### **Features:**
- **Overview Tab**: Total players, games played, top performers, recent activity
- **Players Tab**: Search, sort, and view all players
- **Games Tab**: Statistics for each game type
- **Player Details**: Individual player profiles with recent scores

### **Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DashboardPage(),
  ),
);
```

## 🌐 **Web Dashboard** (`lib/web/pages/dashboard_page.dart`)

### **Features:**
- **Responsive Design**: Optimized for desktop and tablet
- **Enhanced UI**: Larger cards and better spacing
- **Web-specific Navigation**: Integrated with web routing
- **Player Details**: Dedicated web player detail pages

### **Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WebDashboardPage(),
  ),
);
```

## 🎮 **Game Integration**

### **How Games Save Scores:**
```dart
// After game completion
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

### **Supported Game Types:**
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

## 📊 **Dashboard Features**

### **1. Overview Tab**
- **Total Players**: Count of all registered users
- **Games Played**: Total number of game attempts
- **Top Performers**: Top 5 players by overall score
- **Recent Activity**: Latest achievements and scores

### **2. Players Tab**
- **Search**: Find players by name or ID
- **Sorting**: Sort by overall score, total games, or last played
- **Player Cards**: Display player stats and rankings
- **Player Details**: Tap to view detailed profiles

### **3. Games Tab**
- **Game Statistics**: Top score, average, and player count per game
- **Performance Metrics**: Compare performance across games
- **Visual Indicators**: Color-coded game types and icons

## 🔍 **Search and Filtering**

### **Player Search:**
```dart
// Search by player ID prefix
final players = DashboardService.searchPlayers('user123');
```

### **Sorting Options:**
```dart
// Sort by different criteria
final players = DashboardService.getAllPlayers(
  sortBy: 'overallScore', // 'overallScore', 'totalGames', 'lastPlayed'
  descending: true,
  limit: 100,
);
```

## 📈 **Real-time Updates**

### **Live Data:**
- **Stream-based**: All data updates in real-time
- **Firebase Integration**: Automatic synchronization
- **Performance Optimized**: Efficient queries and caching

### **Update Triggers:**
- New game scores
- High score achievements
- Player registration
- Game completion

## 🎨 **UI Components**

### **ScoreDisplay Widget:**
- Shows personal scores and statistics
- Links to leaderboards
- Displays game-specific information

### **Player Cards:**
- Rank indicators (gold, silver, bronze)
- Overall score display
- Game count and last played date

### **Activity Cards:**
- Recent achievements
- High score indicators
- Game type icons and colors

## 🚀 **Usage Examples**

### **Display Dashboard:**
```dart
// In your main navigation
DashboardPage(), // Mobile
WebDashboardPage(), // Web
```

### **Get Dashboard Data:**
```dart
// Get overview statistics
final overview = await DashboardService.getDashboardOverview();

// Get all players
final players = DashboardService.getAllPlayers(limit: 50);

// Get game leaderboard
final leaderboard = DashboardService.getGameLeaderboard(GameType.reactionTime);
```

### **Player Details:**
```dart
// Navigate to player details
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlayerDetailPage(playerId: 'user123'),
  ),
);
```

## 🔧 **Setup Requirements**

### **Firebase Configuration:**
1. Ensure Firebase is initialized
2. Firestore collections: `user_scores`, `game_scores`
3. Proper security rules for read access

### **Dependencies:**
```yaml
dependencies:
  cloud_firestore: ^latest
  flutter_riverpod: ^latest
  google_fonts: ^latest
  gap: ^latest
```

## 📱 **Platform Support**

### **Mobile (Flutter):**
- ✅ Full dashboard functionality
- ✅ Player search and filtering
- ✅ Real-time updates
- ✅ Player detail pages

### **Web (Flutter Web):**
- ✅ Responsive dashboard design
- ✅ Enhanced web UI
- ✅ Web-specific navigation
- ✅ Cross-platform compatibility

## 🎯 **Key Benefits**

### **For Players:**
- **Progress Tracking**: See improvement over time
- **Competition**: Compare scores with others
- **Achievements**: Track high scores and milestones
- **Social Features**: View other players' performance

### **For Developers:**
- **Unified System**: Same backend for mobile and web
- **Scalable Architecture**: Handles growing user base
- **Real-time Updates**: Instant data synchronization
- **Easy Integration**: Simple API for new games

## 🚀 **Future Enhancements**

### **Advanced Features:**
- **Friend System**: Add friends and compare scores
- **Achievement Badges**: Unlockable achievements
- **Performance Analytics**: Detailed performance graphs
- **Tournament Mode**: Competitive events and challenges

### **Analytics Dashboard:**
- **Player Retention**: Track player engagement
- **Game Performance**: Analyze game difficulty and popularity
- **User Behavior**: Understand how players interact with games

## 🐛 **Troubleshooting**

### **Common Issues:**

1. **Dashboard not loading**
   - Check Firebase connection
   - Verify Firestore permissions
   - Check console for errors

2. **Scores not updating**
   - Ensure ScoreService is called after games
   - Check Firebase authentication
   - Verify data structure

3. **Performance issues**
   - Limit query results
   - Use proper indexing
   - Implement pagination for large datasets

### **Debug Commands:**
```dart
// Check dashboard data
final overview = await DashboardService.getDashboardOverview();
print('Total players: ${overview.totalUsers}');

// Verify player data
final players = await DashboardService.getAllPlayers(limit: 5).first;
print('Players loaded: ${players.length}');
```

## 📚 **API Reference**

### **DashboardService Methods:**

| Method | Description | Returns |
|--------|-------------|---------|
| `getDashboardOverview()` | Get overall statistics | `Future<DashboardOverview>` |
| `getAllPlayers()` | Get all players | `Stream<List<PlayerDashboardData>>` |
| `getGameLeaderboard()` | Get game leaderboard | `Stream<List<PlayerDashboardData>>` |
| `searchPlayers()` | Search players | `Stream<List<PlayerDashboardData>>` |
| `getPlayerDetails()` | Get player details | `Future<PlayerDetailData?>` |

### **Dashboard Models:**

| Model | Description | Key Properties |
|-------|-------------|----------------|
| `DashboardOverview` | Overall dashboard data | `totalUsers`, `topPerformers`, `recentActivity` |
| `PlayerDashboardData` | Player summary | `userId`, `overallScore`, `totalGamesPlayed` |
| `PlayerDetailData` | Detailed player info | `userScore`, `recentScores`, `performanceTrends` |
| `RecentActivity` | Recent achievements | `userId`, `gameType`, `score`, `isHighScore` |
| `GameStatistics` | Game performance | `topScore`, `averageScore`, `playerCount` |

## 🤝 **Contributing**

To add dashboard support for a new game:

1. **Update GameType enum** with new game type
2. **Add scoring calls** in game completion logic
3. **Test dashboard integration** with new game
4. **Update documentation** with new game details

## 📄 **License**

This dashboard system is part of the Human Benchmark application and follows the same license terms.

---

## 🎉 **Quick Start**

1. **Add Dashboard to Navigation:**
   ```dart
   DashboardPage(), // Mobile
   WebDashboardPage(), // Web
   ```

2. **Ensure Games Save Scores:**
   ```dart
   await ScoreService.submitGameScore(
     gameType: GameType.yourGame,
     score: playerScore,
   );
   ```

3. **Test Dashboard:**
   - Play games to generate scores
   - View dashboard to see player data
   - Test search and filtering
   - Navigate to player details

Your dashboard system is now ready to track all players and their performance across all games! 🚀
