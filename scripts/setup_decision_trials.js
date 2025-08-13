const admin = require('firebase-admin');

// See setup_personality_data.js for instructions to place your service key
const serviceAccount = require('./human-benchmark-80a9a-firebase-adminsdk-fbsvc-8ce68a17d3.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function makeMoneyTrial(id, sureAmount, riskyProb, riskyPayoff) {
  return {
    prompt: `You can take $${sureAmount} now or a ${Math.round(riskyProb * 100)}% chance to win $${riskyPayoff}. Which do you choose?`,
    timeLimitSeconds: 10,
    active: true,
    category: 'monetary',
    left: {
      label: `Take $${sureAmount} now`,
      description: 'Guaranteed, no risk',
      isRisky: false,
      probability: 1,
      payoff: sureAmount,
      score: sureAmount / 10,
    },
    right: {
      label: `${Math.round(riskyProb * 100)}% chance to win $${riskyPayoff}`,
      description: 'High risk, high reward',
      isRisky: true,
      probability: riskyProb,
      payoff: riskyPayoff,
      score: (riskyProb * riskyPayoff) / 10,
    },
  };
}

function makeFramingTrial(id, safeLabel, riskyLabel) {
  return {
    prompt: 'Choose quickly between a safe and an uncertain option.',
    timeLimitSeconds: 10,
    active: true,
    category: 'framing',
    left: {
      label: safeLabel,
      description: 'Predictable outcome',
      isRisky: false,
      probability: 1,
      payoff: 1,
      score: 0.5,
    },
    right: {
      label: riskyLabel,
      description: 'Uncertain outcome',
      isRisky: true,
      probability: 0.5,
      payoff: 2,
      score: 0.8,
    },
  };
}

function makeContextTrial(id, category, prompt, safeLabel, riskyLabel, opts = {}) {
  // Provide reasonable defaults for scoring and EV-like fields
  const {
    safePayoff = 1,
    riskyProb = 0.5,
    riskyPayoff = 2,
    safeScore = 0.5,
    riskyScore = 0.8,
  } = opts;
  return {
    prompt,
    timeLimitSeconds: 10,
    active: true,
    category,
    left: {
      label: safeLabel,
      description: 'Predictable outcome',
      isRisky: false,
      probability: 1,
      payoff: safePayoff,
      score: safeScore,
    },
    right: {
      label: riskyLabel,
      description: 'Uncertain outcome',
      isRisky: true,
      probability: riskyProb,
      payoff: riskyPayoff,
      score: riskyScore,
    },
  };
}

async function setupDecisionTrials() {
  console.log('Seeding ~200 decision-making trials...');
  const batch = db.batch();

  let id = 0;
  const trials = [];
  // Build 10 categories × 20 each = 200
  const categories = [
    'monetary_gain',
    'monetary_loss',
    'career',
    'investment',
    'travel',
    'social',
    'health_fitness',
    'technology',
    'education',
    'lifestyle',
  ];

  const perCategory = 20;

  // monetary_gain: use EV-style generator
  for (let i = 0; i < perCategory; i++) {
    const sure = 10 + i * 5; // 10..105
    const prob = 0.2 + (i % 7) * 0.1; // 0.2..0.8
    const riskyPayoff = sure * (2 + (i % 3)); // 2x..4x
    trials.push(makeMoneyTrial(++id, sure, Math.min(prob, 0.9), riskyPayoff));
  }

  // monetary_loss: lose now vs chance of bigger loss
  for (let i = 0; i < perCategory; i++) {
    const sureLoss = 8 + i * 4; // 8..84
    const prob = 0.2 + (i % 6) * 0.12; // 0.2..0.92
    const riskyLoss = sureLoss * (2 + (i % 3));
    trials.push(
      makeContextTrial(
        ++id,
        'monetary_loss',
        `Lose $${sureLoss} now or a ${Math.round(Math.min(prob, 0.95) * 100)}% chance to lose $${riskyLoss}?`,
        `Accept $${sureLoss} loss now`,
        `${Math.round(Math.min(prob, 0.95) * 100)}% chance to lose $${riskyLoss}`,
        { safePayoff: 1, riskyProb: Math.min(prob, 0.95), riskyPayoff: 2, safeScore: 0.4, riskyScore: 0.6 }
      )
    );
  }

  // career
  const careerPairs = [
    ['Safe & steady job', 'Exciting & uncertain job'],
    ['Stable company role', 'Early-stage startup role'],
    ['Keep current position', 'Apply for ambitious role'],
    ['Local offer', 'Relocation to fast-growing hub'],
  ];
  for (let i = 0; i < perCategory; i++) {
    const pair = careerPairs[i % careerPairs.length];
    trials.push(
      makeContextTrial(
        ++id,
        'career',
        'You must choose between two job offers in 10 seconds.',
        `${pair[0]} (#${i + 1})`,
        `${pair[1]} (#${i + 1})`,
        { safeScore: 0.5, riskyScore: 0.9, riskyProb: 0.5, riskyPayoff: 2 }
      )
    );
  }

  // investment
  const investSafe = ['Government bonds', 'Index fund', 'Blue-chip stock'];
  const investRisky = ['Crypto asset', 'Leveraged ETF', 'Emerging startup'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'investment',
        'Pick an investment strategy quickly.',
        `${investSafe[i % investSafe.length]} (#${i + 1})`,
        `${investRisky[i % investRisky.length]} (#${i + 1})`,
        { safeScore: 0.6, riskyScore: 1.0, riskyProb: 0.45 + (i % 4) * 0.1, riskyPayoff: 3 }
      )
    );
  }

  // travel
  const travelSafe = ['Direct flight', 'Familiar destination', 'Guided tour'];
  const travelRisky = ['Multi-stop saver', 'Remote destination', 'Solo backpacking'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'travel',
        'Vacation planning: decide fast.',
        `${travelSafe[i % travelSafe.length]} (#${i + 1})`,
        `${travelRisky[i % travelRisky.length]} (#${i + 1})`,
        { safeScore: 0.5, riskyScore: 0.8, riskyProb: 0.6, riskyPayoff: 2 }
      )
    );
  }

  // social
  const socialSafe = ['Small gathering', 'Dinner with friends', 'Stay home'];
  const socialRisky = ['Large party', 'Public speaking', 'Network event'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'social',
        'Social plan: choose now.',
        `${socialSafe[i % socialSafe.length]} (#${i + 1})`,
        `${socialRisky[i % socialRisky.length]} (#${i + 1})`,
        { safeScore: 0.4, riskyScore: 0.9, riskyProb: 0.5, riskyPayoff: 2 }
      )
    );
  }

  // health_fitness
  const healthSafe = ['Moderate workout', 'Balanced meal plan', 'Regular sleep'];
  const healthRisky = ['Max intensity HIIT', 'Crash diet', 'All-nighter project'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'health_fitness',
        'Health & fitness decision under time pressure.',
        `${healthSafe[i % healthSafe.length]} (#${i + 1})`,
        `${healthRisky[i % healthRisky.length]} (#${i + 1})`,
        { safeScore: 0.7, riskyScore: 0.6, riskyProb: 0.4, riskyPayoff: 1.5 }
      )
    );
  }

  // technology
  const techSafe = ['Stable LTS stack', 'Proven framework', 'Vendor-supported tool'];
  const techRisky = ['New beta framework', 'In-house experimental tool', 'Unproven library'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'technology',
        'Choose a technology approach quickly.',
        `${techSafe[i % techSafe.length]} (#${i + 1})`,
        `${techRisky[i % techRisky.length]} (#${i + 1})`,
        { safeScore: 0.6, riskyScore: 1.0, riskyProb: 0.5, riskyPayoff: 3 }
      )
    );
  }

  // education
  const eduSafe = ['Accredited course', 'Structured curriculum', 'Certified path'];
  const eduRisky = ['Self-taught sprint', 'Drop into advanced class', 'Skip fundamentals'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'education',
        'Education plan: pick one in 10s.',
        `${eduSafe[i % eduSafe.length]} (#${i + 1})`,
        `${eduRisky[i % eduRisky.length]} (#${i + 1})`,
        { safeScore: 0.7, riskyScore: 0.9, riskyProb: 0.45, riskyPayoff: 2.5 }
      )
    );
  }

  // lifestyle
  const lifeSafe = ['Keep routine', 'Budget spending', 'Cook at home'];
  const lifeRisky = ['Spontaneous trip', 'Big purchase now', 'Dine out often'];
  for (let i = 0; i < perCategory; i++) {
    trials.push(
      makeContextTrial(
        ++id,
        'lifestyle',
        'Lifestyle choice: decide fast.',
        `${lifeSafe[i % lifeSafe.length]} (#${i + 1})`,
        `${lifeRisky[i % lifeRisky.length]} (#${i + 1})`,
        { safeScore: 0.5, riskyScore: 0.8, riskyProb: 0.55, riskyPayoff: 2 }
      )
    );
  }

  trials.forEach((t) => {
    const docRef = db.collection('decision_trials').doc();
    batch.set(docRef, t);
  });

  await batch.commit();
  console.log('✅ Seeded', trials.length, 'decision trials');
}

setupDecisionTrials().catch((e) => {
  console.error(e);
  process.exit(1);
});


