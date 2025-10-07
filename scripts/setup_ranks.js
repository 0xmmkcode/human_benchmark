const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./human-benchmark-80a9a-firebase-adminsdk-fbsvc-8ce68a17d3.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://human-benchmark-80a9a-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

// Default ranks configuration
const defaultRanks = [
  {
    id: 'rookie',
    name: 'Rookie',
    description: 'Just getting started on your cognitive journey',
    minGlobalScore: 0,
    maxGlobalScore: 999,
    color: '#6B7280',
    icon: 'person',
    order: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'novice',
    name: 'Novice',
    description: 'Developing your mental abilities',
    minGlobalScore: 1000,
    maxGlobalScore: 1999,
    color: '#10B981',
    icon: 'school',
    order: 2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'apprentice',
    name: 'Apprentice',
    description: 'Showing consistent improvement',
    minGlobalScore: 2000,
    maxGlobalScore: 2999,
    color: '#3B82F6',
    icon: 'trending_up',
    order: 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'adept',
    name: 'Adept',
    description: 'Mastering multiple cognitive domains',
    minGlobalScore: 3000,
    maxGlobalScore: 3999,
    color: '#8B5CF6',
    icon: 'star',
    order: 4,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'expert',
    name: 'Expert',
    description: 'Exceptional cognitive performance',
    minGlobalScore: 4000,
    maxGlobalScore: 4999,
    color: '#F59E0B',
    icon: 'emoji_events',
    order: 5,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'master',
    name: 'Master',
    description: 'Elite level cognitive abilities',
    minGlobalScore: 5000,
    maxGlobalScore: 5999,
    color: '#EF4444',
    icon: 'military_tech',
    order: 6,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'grandmaster',
    name: 'Grandmaster',
    description: 'Transcendent cognitive performance',
    minGlobalScore: 6000,
    maxGlobalScore: 6999,
    color: '#DC2626',
    icon: 'workspace_premium',
    order: 7,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'champion',
    name: 'Champion',
    description: 'Top-tier consistent performance',
    minGlobalScore: 7000,
    maxGlobalScore: 7999,
    color: '#0EA5E9',
    icon: 'workspace_premium',
    order: 8,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'mythic',
    name: 'Mythic',
    description: 'Exceptional mastery across domains',
    minGlobalScore: 8000,
    maxGlobalScore: 8999,
    color: '#A855F7',
    icon: 'workspace_premium',
    order: 9,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'legend',
    name: 'Legend',
    description: 'Transcendent cognitive performance',
    minGlobalScore: 9000,
    maxGlobalScore: 999999,
    color: '#DC2626',
    icon: 'workspace_premium',
    order: 10,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function setupRanks() {
  try {
    console.log('🚀 Starting ranks setup...');

    // Check if ranks collection already exists
    const ranksSnapshot = await db.collection('ranks').get();
    
    if (!ranksSnapshot.empty) {
      console.log('⚠️  Ranks collection already exists with', ranksSnapshot.size, 'documents');
      console.log('🔄 Updating existing ranks...');
      
      // Update existing ranks
      const batch = db.batch();
      for (const rank of defaultRanks) {
        const rankRef = db.collection('ranks').doc(rank.id);
        batch.set(rankRef, rank, { merge: true });
      }
      await batch.commit();
      
      console.log('✅ Ranks updated successfully!');
    } else {
      console.log('📝 Creating new ranks collection...');
      
      // Create new ranks
      const batch = db.batch();
      for (const rank of defaultRanks) {
        const rankRef = db.collection('ranks').doc(rank.id);
        batch.set(rankRef, rank);
      }
      await batch.commit();
      
      console.log('✅ Ranks created successfully!');
    }

    // Verify the setup
    const verifySnapshot = await db.collection('ranks').orderBy('order').get();
    console.log('\n📊 Ranks in database:');
    verifySnapshot.docs.forEach((doc) => {
      const data = doc.data();
      console.log(`  ${data.order}. ${data.name} (${data.minGlobalScore}-${data.maxGlobalScore}) - ${data.color}`);
    });

    console.log('\n🎉 Ranks setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting up ranks:', error);
    process.exit(1);
  }
}

// Run the setup
setupRanks();
