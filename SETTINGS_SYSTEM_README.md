# Human Benchmark - Settings System

This document explains the comprehensive settings system that stores user preferences in Firebase and is only accessible to authenticated users.

## 🎯 **Overview**

The settings system provides:
- **User-specific preferences** stored in Firebase
- **Authentication-required access** - only visible to signed-in users
- **Real-time synchronization** across devices
- **Game-specific settings** for customization
- **Theme and language** preferences
- **Privacy controls** and notification settings

## 🔐 **Authentication Requirements**

### **Access Control:**
- Settings are **ONLY visible** to authenticated users
- Unauthenticated users see a sign-in prompt
- Anonymous authentication is supported for quick access
- All settings are tied to the user's Firebase UID

### **User States:**
1. **Not Authenticated**: Shows sign-in screen with lock icon
2. **Loading**: Shows loading spinner while fetching settings
3. **Error**: Shows error state with retry option
4. **Authenticated**: Shows full settings interface

## 🏗️ **Architecture**

### **UserSettings Model** (`lib/models/user_settings.dart`)
```dart
class UserSettings {
  final String userId;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final String theme;
  final String language;
  final bool autoSaveEnabled;
  final bool showTutorials;
  final Map<String, dynamic> gameSpecificSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### **SettingsService** (`lib/services/settings_service.dart`)
- **getUserSettings()** - Fetch user settings from Firebase
- **getUserSettingsStream()** - Real-time settings updates
- **updateUserSettings()** - Update entire settings object
- **updateSetting()** - Update specific setting
- **updateGameSettings()** - Update game-specific preferences
- **resetToDefaults()** - Reset to default values
- **deleteUserSettings()** - Clean up on account deletion

## 📱 **Mobile Settings** (`lib/screens/settings_page.dart`)

### **Features:**
- **User Info Card**: Shows profile picture, name, and last updated
- **General Settings**: Sound, vibration, notifications, auto-save, tutorials
- **Appearance**: Theme (light/dark/system) and language selection
- **Game Settings**: Placeholder for future game-specific customization
- **Actions**: Reset to defaults and sign out
- **Settings Summary**: Overview of current configuration

### **Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SettingsPage(),
  ),
);
```

## 🌐 **Web Settings** (`lib/web/pages/settings_page.dart`)

### **Features:**
- **Responsive Design**: Optimized for desktop and tablet
- **Enhanced UI**: Larger cards and better spacing
- **Web-specific Navigation**: Integrated with web routing
- **Same Functionality**: All mobile features available on web

### **Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WebSettingsPage(),
  ),
);
```

## ⚙️ **Available Settings**

### **General Settings:**
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `soundEnabled` | bool | true | Enable sound effects in games |
| `vibrationEnabled` | bool | true | Enable vibration feedback |
| `notificationsEnabled` | bool | true | Enable push notifications |
| `autoSaveEnabled` | bool | true | Automatically save game progress |
| `showTutorials` | bool | true | Show tutorial hints for new users |

### **Appearance Settings:**
| Setting | Type | Default | Options |
|---------|------|---------|---------|
| `theme` | String | 'system' | 'light', 'dark', 'system' |
| `language` | String | 'en' | 'en', 'es', 'fr', 'de' |

### **Game-Specific Settings:**
```dart
gameSpecificSettings: {
  'reactionTime': {
    'rounds': 5,
    'showMilliseconds': true,
    'difficulty': 'normal',
  },
  'decisionRisk': {
    'showProbability': true,
    'autoAdvance': false,
  },
  'personalityQuiz': {
    'showProgress': true,
    'saveAnswers': true,
  },
}
```

## 🔄 **Real-time Updates**

### **Stream-based Updates:**
```dart
// Listen to settings changes
StreamBuilder<UserSettings?>(
  stream: SettingsService.getUserSettingsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final settings = snapshot.data!;
      // Update UI with new settings
    }
  },
)
```

### **Update Triggers:**
- Setting toggle changes
- Theme/language selection
- Game-specific setting updates
- Reset to defaults
- User authentication state changes

## 🎨 **Theme System**

### **Theme Options:**
- **Light**: Bright, high-contrast interface
- **Dark**: Dark, eye-friendly interface
- **System**: Follows device theme preference

### **Implementation:**
```dart
// Get current theme
final theme = SettingsService.getThemeMode(settings);

// Check specific theme
if (settings.isDarkMode) {
  // Apply dark theme
} else if (settings.isLightMode) {
  // Apply light theme
} else {
  // Apply system theme
}
```

## 🌍 **Language System**

### **Supported Languages:**
- **English (en)**: Default language
- **Spanish (es)**: Español
- **French (fr)**: Français
- **German (de)**: Deutsch

### **Implementation:**
```dart
// Get current language
final language = SettingsService.getLanguage(settings);

// Check specific language
if (settings.isEnglish) {
  // Show English text
} else if (settings.isSpanish) {
  // Show Spanish text
}
```

## 🎮 **Game Integration**

### **Accessing Game Settings:**
```dart
// Get settings for specific game
final gameSettings = settings.getGameSettings('reactionTime');
final rounds = gameSettings['rounds'] ?? 5;

// Update game settings
final newSettings = settings.updateGameSettings('reactionTime', {
  'rounds': 10,
  'difficulty': 'hard',
});
```

### **Game-Specific Features:**
- **Reaction Time**: Rounds, millisecond display, difficulty
- **Decision Risk**: Probability display, auto-advance
- **Personality Quiz**: Progress display, answer saving
- **Extensible**: Easy to add new games and settings

## 🔧 **Firebase Integration**

### **Collections:**
- **`user_settings`**: User preferences and configuration
- **Document ID**: User's Firebase UID
- **Real-time**: Automatic synchronization across devices

### **Data Structure:**
```json
{
  "userId": "user123",
  "soundEnabled": true,
  "vibrationEnabled": true,
  "notificationsEnabled": true,
  "theme": "system",
  "language": "en",
  "autoSaveEnabled": true,
  "showTutorials": true,
  "gameSpecificSettings": {
    "reactionTime": {
      "rounds": 5,
      "showMilliseconds": true,
      "difficulty": "normal"
    }
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T12:00:00Z"
}
```

### **Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /user_settings/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 **Usage Examples**

### **Get User Settings:**
```dart
// Fetch settings once
final settings = await SettingsService.getUserSettings();

// Listen to real-time updates
StreamBuilder<UserSettings?>(
  stream: SettingsService.getUserSettingsStream(),
  builder: (context, snapshot) {
    // Build UI with settings
  },
)
```

### **Update Settings:**
```dart
// Update single setting
await SettingsService.updateSetting('soundEnabled', false);

// Update game settings
await SettingsService.updateGameSettings('reactionTime', {
  'rounds': 10,
  'difficulty': 'hard',
});

// Reset to defaults
await SettingsService.resetToDefaults();
```

### **Check Setting Values:**
```dart
// Check if setting is enabled
final soundEnabled = SettingsService.isSettingEnabled(settings, 'soundEnabled');

// Get specific value
final theme = SettingsService.getSettingValue(settings, 'theme', 'system');

// Get game setting
final rounds = SettingsService.getGameSetting(settings, 'reactionTime', 'rounds', 5);
```

## 📱 **Platform Support**

### **Mobile (Flutter):**
- ✅ Full settings functionality
- ✅ Real-time updates
- ✅ Theme and language support
- ✅ Game-specific settings
- ✅ Authentication integration

### **Web (Flutter Web):**
- ✅ Responsive settings design
- ✅ Enhanced web UI
- ✅ Same functionality as mobile
- ✅ Cross-platform compatibility

## 🎯 **Key Benefits**

### **For Users:**
- **Personalized Experience**: Customize app behavior
- **Cross-Device Sync**: Settings follow you everywhere
- **Privacy Control**: Manage notifications and data
- **Accessibility**: Theme and language preferences

### **For Developers:**
- **Centralized Storage**: All settings in one place
- **Real-time Updates**: Instant synchronization
- **Easy Integration**: Simple API for new features
- **Scalable**: Handles growing user base

## 🔮 **Future Enhancements**

### **Advanced Features:**
- **Profile Pictures**: Custom avatar selection
- **Advanced Themes**: Custom color schemes
- **Notification Preferences**: Granular notification control
- **Data Export**: Download settings backup
- **Settings Templates**: Share configurations

### **Game-Specific Settings:**
- **Difficulty Levels**: Easy, normal, hard, expert
- **Custom Controls**: Key bindings and gestures
- **Visual Preferences**: Graphics quality, animations
- **Audio Settings**: Music, sound effects, voice

## 🐛 **Troubleshooting**

### **Common Issues:**

1. **Settings not loading**
   - Check Firebase connection
   - Verify user authentication
   - Check Firestore permissions

2. **Settings not updating**
   - Ensure user is authenticated
   - Check Firebase Auth state
   - Verify document permissions

3. **Real-time updates not working**
   - Check StreamBuilder implementation
   - Verify Firebase connection
   - Check for error handling

### **Debug Commands:**
```dart
// Check authentication status
final isAuth = SettingsService.isUserAuthenticated;
print('User authenticated: $isAuth');

// Check settings data
final settings = await SettingsService.getUserSettings();
print('Settings loaded: ${settings != null}');

// Validate settings
final isValid = SettingsService.validateSettings(settings!);
print('Settings valid: $isValid');
```

## 📚 **API Reference**

### **SettingsService Methods:**

| Method | Description | Returns |
|--------|-------------|---------|
| `getUserSettings()` | Get user settings | `Future<UserSettings?>` |
| `getUserSettingsStream()` | Stream of settings | `Stream<UserSettings?>` |
| `updateUserSettings()` | Update all settings | `Future<bool>` |
| `updateSetting()` | Update single setting | `Future<bool>` |
| `updateGameSettings()` | Update game settings | `Future<bool>` |
| `resetToDefaults()` | Reset to defaults | `Future<bool>` |
| `deleteUserSettings()` | Delete user settings | `Future<bool>` |

### **Helper Methods:**

| Method | Description | Returns |
|--------|-------------|---------|
| `isSettingEnabled()` | Check if setting is on | `bool` |
| `getSettingValue()` | Get setting value | `T` |
| `getThemeMode()` | Get current theme | `String` |
| `getLanguage()` | Get current language | `String` |
| `getGameSetting()` | Get game setting | `T` |
| `validateSettings()` | Validate settings | `bool` |

## 🤝 **Contributing**

To add new settings:

1. **Update UserSettings Model** with new fields
2. **Add Default Values** in `UserSettings.defaults()`
3. **Update SettingsService** with getter/setter methods
4. **Add UI Controls** in settings pages
5. **Test Integration** across platforms

## 📄 **License**

This settings system is part of the Human Benchmark application and follows the same license terms.

---

## 🎉 **Quick Start**

1. **Add Settings to Navigation:**
   ```dart
   SettingsPage(), // Mobile
   WebSettingsPage(), // Web
   ```

2. **Check Authentication:**
   ```dart
   if (SettingsService.isUserAuthenticated) {
     // Show settings
   } else {
     // Show sign-in prompt
   }
   ```

3. **Load and Display Settings:**
   ```dart
   StreamBuilder<UserSettings?>(
     stream: SettingsService.getUserSettingsStream(),
     builder: (context, snapshot) {
       if (snapshot.hasData) {
         final settings = snapshot.data!;
         // Build settings UI
       }
     },
   )
   ```

4. **Update Settings:**
   ```dart
   await SettingsService.updateSetting('soundEnabled', false);
   ```

Your settings system is now ready to provide personalized experiences for authenticated users! 🚀
