#!/bin/bash

echo "🧪 Testing Game Management System..."
echo ""

# Check if Firebase CLI is available
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI found"
echo ""

# Check if we're in the right directory
if [ ! -f "firestore.rules" ]; then
    echo "❌ Not in the correct directory. Please run this from the project root."
    exit 1
fi

echo "✅ In correct directory"
echo ""

# Check if required files exist
echo "📁 Checking required files..."
required_files=(
    "lib/models/game_management.dart"
    "lib/services/game_management_service.dart"
    "lib/services/route_protection_service.dart"
    "lib/web/pages/admin_game_management_page.dart"
    "lib/web/pages/game_not_available_page.dart"
    "lib/web/components/protected_game_route.dart"
    "firestore.rules"
    "firestore.indexes.json"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
    fi
done

echo ""

# Check Flutter dependencies
echo "📱 Checking Flutter dependencies..."
if [ -f "pubspec.yaml" ]; then
    echo "  ✅ pubspec.yaml found"
    
    # Check for required packages
    if grep -q "flutter_riverpod" pubspec.yaml; then
        echo "  ✅ flutter_riverpod found"
    else
        echo "  ❌ flutter_riverpod not found in pubspec.yaml"
    fi
    
    if grep -q "gap" pubspec.yaml; then
        echo "  ✅ gap package found"
    else
        echo "  ❌ gap package not found in pubspec.yaml"
    fi
else
    echo "  ❌ pubspec.yaml not found"
fi

echo ""

# Check if Firestore rules are properly configured
echo "🔐 Checking Firestore rules..."
if grep -q "game_management" firestore.rules; then
    echo "  ✅ game_management collection rules found"
else
    echo "  ❌ game_management collection rules not found"
fi

if grep -q "admin_roles" firestore.rules; then
    echo "  ✅ admin_roles collection rules found"
else
    echo "  ❌ admin_roles collection rules not found"
fi

echo ""

# Check if indexes are properly configured
echo "📊 Checking Firestore indexes..."
if grep -q "game_management" firestore.indexes.json; then
    echo "  ✅ game_management indexes found"
else
    echo "  ❌ game_management indexes not found"
fi

echo ""

echo "🎯 Test Summary:"
echo "  • All required files should be present"
echo "  • Flutter dependencies should be configured"
echo "  • Firestore rules should include game_management"
echo "  • Firestore indexes should be configured"
echo ""
echo "🚀 Next Steps:"
echo "  1. Run: flutter pub get"
echo "  2. Run: ./deploy_game_management.sh"
echo "  3. Test the admin interface"
echo "  4. Verify route protection works"
echo ""
echo "📚 For detailed setup instructions, see: GAME_MANAGEMENT_README.md"

echo "🔐 Security Features:"
echo "   • Only admins can modify game enable/disable status"
echo "   • Anyone can read game status (needed for route protection)"
echo "   • Route protection completely blocks disabled games"
echo "   • No fallback pages - games are completely hidden"
