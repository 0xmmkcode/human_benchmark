const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project-id.firebaseio.com' // Replace with your project ID
});

const db = admin.firestore();

async function setupWebSettings() {
  try {
    console.log('Setting up web settings...');
    
    const webSettingsRef = db.collection('web_settings').doc('main');
    
    // Check if document already exists
    const doc = await webSettingsRef.get();
    
    if (doc.exists) {
      console.log('Web settings already exist, updating...');
    } else {
      console.log('Creating new web settings...');
    }
    
    // Default web settings
    const defaultSettings = {
      webGameEnabled: true, // Enable web game by default
      playStoreLink: 'https://play.google.com/store/apps/details?id=xyz.mmkcode.focusflow',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: 'system'
    };
    
    // Set the document
    await webSettingsRef.set(defaultSettings);
    
    console.log('✅ Web settings initialized successfully!');
    console.log('Settings:', defaultSettings);
    
    // Verify the document was created
    const verifyDoc = await webSettingsRef.get();
    if (verifyDoc.exists) {
      console.log('✅ Verification: Document exists in Firestore');
    } else {
      console.log('❌ Verification failed: Document not found');
    }
    
  } catch (error) {
    console.error('❌ Error setting up web settings:', error);
  } finally {
    process.exit(0);
  }
}

// Run the setup
setupWebSettings();

