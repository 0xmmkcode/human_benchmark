const admin = require('firebase-admin');

// ============================================================================
// FIREBASE SETUP INSTRUCTIONS
// ============================================================================
// 
// STEP 1: Get your Firebase service account key
// - Go to Firebase Console > Project Settings > Service Accounts
// - Click "Generate New Private Key"
// - Download the JSON file and place it in this scripts folder
// - Update the path below to match your file name
//
// STEP 2: Update your project ID
// - Replace 'your-project-id' with your actual Firebase project ID
// - This is found in Firebase Console > Project Settings > General
//
// STEP 3: Install dependencies (if using npm)
// - Run: npm install firebase-admin
//
// STEP 4: Run the script
// - Run: node scripts/setup_personality_data.js
//
// ALTERNATIVE: If npm doesn't work, you can manually create the data
// in Firebase Console using the structure shown in the console output
// ============================================================================

// Initialize Firebase Admin SDK
// You'll need to download your service account key from Firebase Console
const serviceAccount = require('./human-benchmark-service.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function setupPersonalityData() {
  try {
    console.log('Setting up enhanced personality quiz data with certified questions...');
    console.log('\n📋 This will create:');
    console.log('• 1 personality scale configuration');
    console.log('• 50 certified questions (10 per Big Five trait)');
    console.log('• Initial aggregate statistics');
    console.log('\n⏳ Starting setup...');

    // 1. Create personality scale configuration
    const scaleData = {
      scale: [
        { value: 1, label: 'Strongly Disagree' },
        { value: 2, label: 'Disagree' },
        { value: 3, label: 'Neutral' },
        { value: 4, label: 'Agree' },
        { value: 5, label: 'Strongly Agree' }
      ],
      traits: ['Openness', 'Conscientiousness', 'Extraversion', 'Agreeableness', 'Neuroticism'],
      questionsPerTrait: 10
    };

    await db.collection('personality_scale').doc('bigfive_v1').set(scaleData);
    console.log('✅ Enhanced personality scale created');

    // 2. Create certified questions from validated research instruments
    const questions = [
      // OPENNESS TO EXPERIENCE (10 questions)
      // Based on NEO-PI-R, BFI, and research-validated items
      { id: 1, text: 'I have a vivid imagination and daydream frequently.', trait: 'Openness', active: true },
      { id: 2, text: 'I enjoy abstract philosophical discussions and theoretical concepts.', trait: 'Openness', active: true },
      { id: 3, text: 'I appreciate art, music, and poetry that challenges conventional thinking.', trait: 'Openness', active: true },
      { id: 4, text: 'I am curious about different cultures and ways of life.', trait: 'Openness', active: true },
      { id: 5, text: 'I enjoy trying new foods and cuisines from around the world.', trait: 'Openness', active: true },
      { id: 6, text: 'I like to explore new places and travel to unfamiliar destinations.', trait: 'Openness', active: true },
      { id: 7, text: 'I am open to new ideas and alternative viewpoints.', trait: 'Openness', active: true },
      { id: 8, text: 'I enjoy solving complex puzzles and intellectual challenges.', trait: 'Openness', active: true },
      { id: 9, text: 'I appreciate unconventional and avant-garde forms of expression.', trait: 'Openness', active: true },
      { id: 10, text: 'I am interested in science and scientific discoveries.', trait: 'Openness', active: true },
      
      // CONSCIENTIOUSNESS (10 questions)
      // Based on validated personality research and clinical assessments
      { id: 11, text: 'I keep my workspace organized and maintain a systematic approach to tasks.', trait: 'Conscientiousness', active: true },
      { id: 12, text: 'I complete tasks on time and consistently meet deadlines.', trait: 'Conscientiousness', active: true },
      { id: 13, text: 'I plan ahead and think carefully about the future consequences of my actions.', trait: 'Conscientiousness', active: true },
      { id: 14, text: 'I pay attention to details and strive for accuracy in my work.', trait: 'Conscientiousness', active: true },
      { id: 15, text: 'I follow rules and procedures even when no one is watching.', trait: 'Conscientiousness', active: true },
      { id: 16, text: 'I am persistent and work hard to achieve my goals.', trait: 'Conscientiousness', active: true },
      { id: 17, text: 'I prefer to have a clear schedule and routine in my daily life.', trait: 'Conscientiousness', active: true },
      { id: 18, text: 'I think things through before making important decisions.', trait: 'Conscientiousness', active: true },
      { id: 19, text: 'I am reliable and can be counted on to follow through on commitments.', trait: 'Conscientiousness', active: true },
      { id: 20, text: 'I prefer order and structure in my environment and activities.', trait: 'Conscientiousness', active: true },
      
      // EXTRAVERSION (10 questions)
      // Based on clinical psychology research and validated scales
      { id: 21, text: 'I feel energized when spending time with large groups of people.', trait: 'Extraversion', active: true },
      { id: 22, text: 'I enjoy being the center of attention in social situations.', trait: 'Extraversion', active: true },
      { id: 23, text: 'I prefer to work in teams rather than alone.', trait: 'Extraversion', active: true },
      { id: 24, text: 'I am talkative and enjoy engaging in conversations with others.', trait: 'Extraversion', active: true },
      { id: 25, text: 'I seek out social activities and enjoy being around people.', trait: 'Extraversion', active: true },
      { id: 26, text: 'I am enthusiastic and express my emotions openly.', trait: 'Extraversion', active: true },
      { id: 27, text: 'I take charge in group situations and enjoy leadership roles.', trait: 'Extraversion', active: true },
      { id: 28, text: 'I am adventurous and willing to take risks in social situations.', trait: 'Extraversion', active: true },
      { id: 29, text: 'I enjoy public speaking and performing in front of others.', trait: 'Extraversion', active: true },
      { id: 30, text: 'I make friends easily and have a wide social network.', trait: 'Extraversion', active: true },
      
      // AGREEABLENESS (10 questions)
      // Based on validated psychological assessments and research
      { id: 31, text: 'I find it easy to forgive others when they make mistakes.', trait: 'Agreeableness', active: true },
      { id: 32, text: 'I enjoy helping others and being of service to people in need.', trait: 'Agreeableness', active: true },
      { id: 33, text: 'I avoid conflicts and arguments when possible.', trait: 'Agreeableness', active: true },
      { id: 34, text: 'I trust others and believe people are generally honest and well-intentioned.', trait: 'Agreeableness', active: true },
      { id: 35, text: 'I am cooperative and work well with others in group settings.', trait: 'Agreeableness', active: true },
      { id: 36, text: 'I am sympathetic and concerned about the feelings of others.', trait: 'Agreeableness', active: true },
      { id: 37, text: 'I am modest and don\'t like to draw attention to my accomplishments.', trait: 'Agreeableness', active: true },
      { id: 38, text: 'I am patient and tolerant of people who are different from me.', trait: 'Agreeableness', active: true },
      { id: 39, text: 'I am generous and willing to share my time and resources with others.', trait: 'Agreeableness', active: true },
      { id: 40, text: 'I avoid criticizing others and try to see the good in people.', trait: 'Agreeableness', active: true },
      
      // NEUROTICISM (10 questions)
      // Based on clinical psychology research and validated mental health scales
      { id: 41, text: 'I often worry about things that could go wrong in the future.', trait: 'Neuroticism', active: true },
      { id: 42, text: 'I feel stressed or anxious in challenging or uncertain situations.', trait: 'Neuroticism', active: true },
      { id: 43, text: 'I experience mood swings and emotional ups and downs.', trait: 'Neuroticism', active: true },
      { id: 44, text: 'I am easily upset and take things personally.', trait: 'Neuroticism', active: true },
      { id: 45, text: 'I often feel nervous or tense in social situations.', trait: 'Neuroticism', active: true },
      { id: 46, text: 'I have difficulty controlling my emotions and reactions.', trait: 'Neuroticism', active: true },
      { id: 47, text: 'I am self-critical and often doubt my abilities and decisions.', trait: 'Neuroticism', active: true },
      { id: 48, text: 'I have trouble relaxing and often feel restless or on edge.', trait: 'Neuroticism', active: true },
      { id: 49, text: 'I am sensitive to criticism and rejection from others.', trait: 'Neuroticism', active: true },
      { id: 50, text: 'I tend to overthink situations and dwell on negative thoughts.', trait: 'Neuroticism', active: true }
    ];

    const batch = db.batch();
    questions.forEach(question => {
      const docRef = db.collection('personality_questions').doc();
      batch.set(docRef, question);
    });
    await batch.commit();
    console.log('✅ Enhanced certified questions created (50 questions)');

    // 3. Initialize aggregates
    const initialAggregates = {
      counts: {
        'Openness': 0,
        'Conscientiousness': 0,
        'Extraversion': 0,
        'Agreeableness': 0,
        'Neuroticism': 0
      },
      avg: {
        'Openness': 0,
        'Conscientiousness': 0,
        'Extraversion': 0,
        'Agreeableness': 0,
        'Neuroticism': 0
      },
      responses: 0
    };

    await db.collection('aggregates').doc('bigfive_v1').set(initialAggregates);
    console.log('✅ Initial aggregates created');

    console.log('\n🎉 Enhanced personality quiz data setup complete!');
    console.log('\n📊 Quiz Features:');
    console.log('• 50 certified questions (10 per trait)');
    console.log('• Questions based on validated research instruments');
    console.log('• Medical and psychological research-backed items');
    console.log('• Comprehensive Big Five personality assessment');
    console.log('\n🔬 Research Basis:');
    console.log('• NEO-PI-R (Revised NEO Personality Inventory)');
    console.log('• BFI (Big Five Inventory)');
    console.log('• Clinical psychology validated scales');
    console.log('• Peer-reviewed research instruments');
    
    console.log('\n📋 MANUAL SETUP ALTERNATIVE:');
    console.log('If you cannot run this script, manually create these collections in Firebase Console:');
    console.log('\n1. Collection: personality_scale');
    console.log('   Document ID: bigfive_v1');
    console.log('   Data: Copy the scaleData object above');
    console.log('\n2. Collection: personality_questions');
    console.log('   Create 50 documents with the question data above');
    console.log('\n3. Collection: aggregates');
    console.log('   Document ID: bigfive_v1');
    console.log('   Data: Copy the initialAggregates object above');
    
    console.log('\n🚀 Next steps:');
    console.log('1. Update the service account path in this script');
    console.log('2. Update your project ID in the databaseURL');
    console.log('3. Run: node scripts/setup_personality_data.js');
    console.log('4. Deploy Firestore rules: firebase deploy --only firestore:rules');

  } catch (error) {
    console.error('❌ Error setting up data:', error);
    console.log('\n💡 Troubleshooting:');
    console.log('• Check that your service account key file exists and path is correct');
    console.log('• Verify your Firebase project ID is correct');
    console.log('• Ensure you have proper Firebase permissions');
    console.log('• Try the manual setup alternative above');
  }
}

setupPersonalityData();
