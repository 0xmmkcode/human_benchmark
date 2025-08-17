const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download your service account key from Firebase Console
// and place it in the project root as 'serviceAccountKey.json'
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://human-benchmark-80a9a.firebaseio.com'
});

const db = admin.firestore();

async function setMaintenanceMode(enabled, message = 'App is under maintenance') {
  try {
    await db.collection('app_settings').doc('maintenance').set({
      isMaintenanceMode: enabled,
      maintenanceMessage: message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: 'admin-script'
    });

    console.log(`✅ Maintenance mode ${enabled ? 'ENABLED' : 'DISABLED'}`);
    console.log(`Message: ${message}`);
    
    if (enabled) {
      console.log('\n🔧 The app is now in maintenance mode.');
      console.log('Users will see the maintenance page when trying to access app routes.');
      console.log('The landing page remains accessible.');
    } else {
      console.log('\n✅ The app is now available to users.');
      console.log('Users can access all app routes normally.');
    }
    
  } catch (error) {
    console.error('❌ Error setting maintenance mode:', error);
  }
}

async function getMaintenanceStatus() {
  try {
    const doc = await db.collection('app_settings').doc('maintenance').get();
    
    if (doc.exists) {
      const data = doc.data();
      console.log('\n📊 Current Maintenance Status:');
      console.log(`Enabled: ${data.isMaintenanceMode ? 'Yes' : 'No'}`);
      console.log(`Message: ${data.maintenanceMessage || 'No message set'}`);
      console.log(`Last Updated: ${data.updatedAt?.toDate() || 'Unknown'}`);
    } else {
      console.log('\n📊 No maintenance settings found.');
      console.log('The app is currently available to users.');
    }
    
  } catch (error) {
    console.error('❌ Error getting maintenance status:', error);
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  switch (command) {
    case 'enable':
      const message = args[1] || 'App is under maintenance';
      await setMaintenanceMode(true, message);
      break;
      
    case 'disable':
      await setMaintenanceMode(false);
      break;
      
    case 'status':
      await getMaintenanceStatus();
      break;
      
    default:
      console.log('🔧 Human Benchmark Maintenance Mode Controller');
      console.log('\nUsage:');
      console.log('  node set_maintenance_mode.js enable [message]  - Enable maintenance mode');
      console.log('  node set_maintenance_mode.js disable           - Disable maintenance mode');
      console.log('  node set_maintenance_mode.js status            - Check current status');
      console.log('\nExamples:');
      console.log('  node set_maintenance_mode.js enable "Scheduled maintenance - back in 2 hours"');
      console.log('  node set_maintenance_mode.js disable');
      console.log('  node set_maintenance_mode.js status');
      break;
  }
  
  process.exit(0);
}

main().catch(console.error);
