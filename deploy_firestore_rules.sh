#!/bin/bash

# Deploy Firestore Security Rules
echo "Deploying Firestore security rules..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "Please log in to Firebase first:"
    echo "firebase login"
    exit 1
fi

# Deploy the rules
echo "Deploying rules to Firestore..."
firebase deploy --only firestore:rules

echo "Firestore rules deployed successfully!"
echo ""
echo "Note: It may take a few minutes for the new rules to take effect."
echo "If you still see permission errors, wait a few minutes and try again."
