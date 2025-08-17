#!/bin/bash

echo "🚀 Deploying Game Management Firestore Rules and Indexes..."

# Deploy Firestore security rules
echo "📋 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
else
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ Firestore indexes deployed successfully!"
else
    echo "❌ Failed to deploy Firestore indexes"
    exit 1
fi

echo "🎉 Game Management deployment completed successfully!"
echo ""
echo "📝 What was deployed:"
echo "   • Firestore security rules for game_management collection"
echo "   • Firestore indexes for optimized game queries"
echo "   • Admin-only access control for game settings"
echo ""
echo "🔐 Security Features:"
echo "   • Only admins can modify game enable/disable status"
echo "   • Anyone can read game status (needed for route protection)"
echo "   • Route protection completely blocks disabled games"
echo "   • No fallback pages - games are completely hidden"
echo ""
echo "🎮 Next Steps:"
echo "   1. Access the Game Management page as an admin"
echo "   2. Configure which games are enabled/disabled"
echo "   3. Test route protection by disabling a game"
echo "   4. Verify disabled games are completely hidden from navigation"
