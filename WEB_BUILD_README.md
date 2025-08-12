# Human Benchmark - Web Version

This project now has two completely separate entry points with different designs:

## 1. Mobile/Desktop Version (`lib/main.dart`)
- **Target**: Android, iOS, Windows, macOS, Linux
- **Features**: Full mobile ads, orientation locking, mobile-specific optimizations
- **Design**: Mobile-first, full-screen layout
- **Build**: `flutter build [platform]`

## 2. Web Version (`lib/web/main.dart`)
- **Target**: Web browsers
- **Features**: Landing page + web app, no mobile ads, responsive design
- **Design**: **Landing page first, then persistent sidebar navigation**
- **Build**: `flutter build web --target lib/web/main.dart`

## 🎨 **Web Version Features**

### **🎯 Landing Page (First Screen)**
- **Mobile App Showcase**: Beautiful landing page that showcases your mobile app
- **"Test Your Brain" Button**: Prominent button in header that takes users to the web app
- **Hero Section**: Large headline and description about cognitive testing
- **Feature Cards**: Highlights reaction time, leaderboard, and cross-platform features
- **Mobile Mockup**: Visual representation of the mobile app
- **Call-to-Action**: Multiple buttons to start testing or learn more

### **🧠 Web App (After Landing)**
- **Persistent Sidebar**: 280px wide sidebar that never closes
- **Back Button**: Arrow button in sidebar to return to landing page
- **Navigation Items**: 
  - Reaction Time Test
  - Leaderboard
  - About (Coming Soon)
  - Settings (Coming Soon)
- **User Profile**: Footer with guest user info and sign-in prompt

### **🎮 Web-Optimized Pages**
- **WebReactionTimePage**: Redesigned for web with larger click areas
- **WebLeaderboardPage**: Full-width table with filters and sorting
- **Responsive Layout**: Optimized for desktop and tablet screens

### **🎨 Visual Design**
- **Material 3**: Modern Flutter design system
- **Color Scheme**: Blue primary with grey accents
- **Typography**: Clear hierarchy with proper font weights
- **Spacing**: Generous padding and margins for web comfort

## 📁 **New Modular Web Structure**

```
lib/
├── main.dart                    # Mobile/Desktop entry point
├── web/                        # 🆕 Web-specific folder
│   ├── main.dart              # Web app entry point (landing + app)
│   ├── pages/                 # Web page components
│   │   ├── landing_page.dart  # 🆕 Landing page with mobile showcase
│   │   ├── reaction_time_page.dart
│   │   └── leaderboard_page.dart
│   ├── components/            # Reusable web components
│   │   ├── web_sidebar.dart   # Updated with back button
│   │   └── web_navigation_item.dart
│   ├── theme/                 # Web-specific theming
│   │   └── web_theme.dart
│   ├── constants/             # Web constants and data
│   │   └── web_constants.dart
│   └── utils/                 # Web utility functions
│       └── web_utils.dart
```

## 🚀 **User Flow**

1. **Landing Page**: Users see beautiful showcase of mobile app
2. **"Test Your Brain" Button**: Click header button to enter web app
3. **Web App**: Full sidebar navigation with game pages
4. **Back to Landing**: Arrow button in sidebar returns to landing page

## 🛠 **Building the Web Version**

### **Quick Build**
```bash
# Windows
build_web.bat

# PowerShell
build_web.ps1

# Manual
flutter build web --target lib/web/main.dart --release
```

### **Development Mode**
```bash
flutter run -d chrome --target lib/web/main.dart
```

## 📱 **Landing Page Sections**

1. **Header**: Logo + navigation + "Test Your Brain" button
2. **Hero**: Large title + description + action buttons
3. **Features**: Three feature cards explaining benefits
4. **Mobile Showcase**: Mock mobile app + download info
5. **Footer**: Copyright + legal links

## 🎯 **Key Benefits**

- **Mobile App Promotion**: Landing page showcases your mobile app
- **Clear Call-to-Action**: "Test Your Brain" button guides users
- **Professional Look**: Modern, web-optimized design
- **Easy Navigation**: Simple flow between landing and app
- **Responsive Design**: Works on all screen sizes

## 🔄 **Navigation Flow**

```
Landing Page → "Test Your Brain" Button → Web App
     ↑                                              ↓
     ←────────── Back Button in Sidebar ←──────────┘
```

## 📋 **Files to Build**

After building, you'll have:
- `build/web/index.html` - Main entry point
- `build/web/main.dart.js` - Flutter web app
- `build/web/assets/` - Images and resources
- `build/web/canvaskit/` - Canvas rendering (if needed)

## 🌐 **Deployment**

Upload the entire `build/web/` folder to any web hosting service:
- Netlify
- Vercel
- GitHub Pages
- Firebase Hosting
- Traditional web hosting

The landing page will be the first thing users see, then they can click "Test Your Brain" to access the full web app!
