# Web Module Structure

This folder contains all web-specific components, pages, and utilities for the Human Benchmark web application.

## 📁 Folder Structure

```
lib/web/
├── main.dart                    # Web app entry point
├── components/                  # Reusable web components
│   ├── web_navigation_item.dart # Navigation item component
│   └── web_sidebar.dart        # Persistent sidebar component
├── pages/                      # Web-specific page implementations
│   ├── reaction_time_page.dart # Web-optimized reaction time page
│   └── leaderboard_page.dart   # Web-optimized leaderboard page
├── theme/                      # Web-specific theming
│   └── web_theme.dart         # Colors, text styles, and decorations
├── constants/                  # Web-specific constants
│   └── web_constants.dart     # Navigation items, categories, etc.
├── utils/                      # Web-specific utilities
│   └── web_utils.dart         # Helper functions and widgets
└── README.md                   # This file
```

## 🎯 Components

### `WebSidebar`
- **Purpose**: Persistent left sidebar that's always visible
- **Features**: Navigation items, user profile, app branding
- **Width**: 280px fixed width
- **State**: Manages selected navigation index

### `WebNavigationItem`
- **Purpose**: Individual navigation item in the sidebar
- **Features**: Icon, title, subtitle, selection state, coming soon badge
- **Interactions**: Tap to navigate, visual feedback

## 📱 Pages

### `WebReactionTimePage`
- **Purpose**: Web-optimized reaction time test
- **Features**: Larger click areas, web-specific animations, statistics display
- **Layout**: Responsive design for desktop/tablet screens

### `WebLeaderboardPage`
- **Purpose**: Web-optimized leaderboard display
- **Features**: Full-width table, advanced filtering, top 3 highlighting
- **Filters**: Category and time frame selection

## 🎨 Theming

### `WebTheme`
- **Colors**: Consistent color palette for web components
- **Text Styles**: Typography hierarchy for web readability
- **Button Styles**: Predefined button styles for consistency
- **Decorations**: Card and container styling
- **Spacing**: Standardized spacing values
- **Shadows**: Subtle shadows for depth

## 🔧 Utilities

### `WebUtils`
- **Icon Mapping**: Convert string names to Flutter icons
- **Color Mapping**: Leaderboard top 3 color logic
- **Date Formatting**: Human-readable date display
- **Widget Builders**: Common UI patterns (loading, empty states, stat cards)

## 📊 Constants

### `WebConstants`
- **Navigation**: Menu structure and configuration
- **Categories**: Leaderboard filter options
- **Game Settings**: Reaction time delays, limits
- **UI Dimensions**: Sidebar width, game area sizes
- **Animation**: Duration constants

## 🚀 Usage

### Building the Web App
```bash
flutter build web --target lib/web/main.dart
```

### Running in Development
```bash
flutter run -d chrome --target lib/web/main.dart
```

### Key Features
- **Persistent Sidebar**: Always visible navigation
- **Web-Optimized UI**: Desktop-first design
- **Responsive Layout**: Adapts to different screen sizes
- **Component Reusability**: Shared components across pages
- **Consistent Theming**: Unified visual design

## 🔄 State Management

- **Navigation State**: Managed in `WebApp` widget
- **Page State**: Each page manages its own state
- **Shared State**: Firebase and services shared with mobile app

## 📱 Responsiveness

- **Sidebar**: Fixed 280px width
- **Content Area**: Flexible width, adapts to screen
- **Game Areas**: Optimized for mouse interaction
- **Typography**: Readable on desktop screens

## 🎯 Design Principles

1. **Web-First**: Designed specifically for desktop web browsers
2. **Persistent Navigation**: Sidebar always visible for easy access
3. **Card-Based Layout**: Clean, organized information display
4. **Consistent Spacing**: Generous padding and margins for web comfort
5. **Visual Hierarchy**: Clear information organization and typography
