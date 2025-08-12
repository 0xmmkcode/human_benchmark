# Firebase Setup Guide for Human Benchmark

## 🚨 **Current Issue: Sign-In Button Not Working**

Your sign-in button isn't working because Firebase isn't properly configured. Here's how to fix it:

## 🔧 **Step-by-Step Setup**

### **1. Install FlutterFire CLI**
```bash
dart pub global activate flutterfire_cli
```

### **2. Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `human-benchmark` (or your preferred name)
4. Follow the setup wizard

### **3. Enable Authentication**
1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Google" provider
3. Add your support email

### **4. Enable Firestore**
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)

### **5. Configure Flutter App**
```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

**Replace `YOUR_PROJECT_ID` with your Firebase project ID**

### **6. Install Dependencies**
```bash
flutter pub get
```

## 📱 **Android Configuration**

### **Add SHA-1 Fingerprint**
1. Get your debug SHA-1:
```bash
cd android
./gradlew signingReport
```

2. Copy the SHA-1 from "debug" variant
3. Add it to Firebase Console → Project Settings → Your Apps → Android app

### **Download google-services.json**
1. In Firebase Console, go to Project Settings
2. Download `google-services.json`
3. Place it in `android/app/`

## 🌐 **Web Configuration**

### **Add Web App**
1. In Firebase Console, click "Add app" → Web
2. Register app with nickname
3. Copy the config object

### **Update index.html**
The FlutterFire CLI should handle this automatically.

## 🧪 **Test the Setup**

### **1. Run the app**
```bash
flutter run
```

### **2. Navigate to Leaderboard**
- Tap the Leaderboard tab
- Look for the "Sign in" button

### **3. Test Sign-In**
- Tap "Sign in"
- Choose your Google account
- Should see "Signed in successfully!"

## 🔍 **Troubleshooting**

### **"Firebase not configured" error**
- Run `flutterfire configure` again
- Check that `lib/firebase_options.dart` was generated

### **Sign-in button still not working**
- Check console for error messages
- Verify `google-services.json` is in `android/app/`
- Ensure Google Sign-In is enabled in Firebase Console

### **Build errors**
- Clean and rebuild: `flutter clean && flutter pub get`
- Check Android SDK version in `android/app/build.gradle`

## 📋 **Required Files After Setup**

```
android/app/google-services.json          # Android config
ios/Runner/GoogleService-Info.plist      # iOS config (if needed)
lib/firebase_options.dart                # Flutter config
web/index.html                           # Web config
```

## 🎯 **What This Fixes**

- ✅ Sign-in button will work
- ✅ Google authentication on mobile
- ✅ User state management
- ✅ Leaderboard integration
- ✅ Cross-platform auth

## 🚀 **Next Steps After Setup**

1. Test sign-in on mobile
2. Test sign-in on web
3. Verify user data appears in Firestore
4. Customize authentication flow if needed

## 📞 **Need Help?**

- Check Firebase Console for error logs
- Verify all configuration files are in place
- Ensure Google Sign-In is enabled
- Check that SHA-1 fingerprint is correct

