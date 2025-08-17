// SEO Configuration for Human Benchmark
const SEO_CONFIG = {
  // Base configuration
  base: {
    title: "Human Benchmark - Test Your Cognitive Limits & Reaction Time",
    description: "Challenge your mind with Human Benchmark's cognitive tests. Measure reaction time, memory, decision-making, and personality traits. Compare scores globally and track your progress.",
    keywords: "human benchmark, cognitive test, reaction time test, memory test, decision making, personality quiz, brain training, cognitive assessment, mental speed, attention test",
    author: "Human Benchmark",
    siteName: "Human Benchmark",
    url: "https://humanbenchmark.xyz",
    image: "https://humanbenchmark.xyz/icons/Icon-512.png",
    locale: "en_US"
  },
  
  // Page-specific configurations
  pages: {
    home: {
      title: "Human Benchmark - Test Your Cognitive Limits & Reaction Time",
      description: "Challenge your mind with Human Benchmark's comprehensive cognitive tests. Measure reaction time, memory, decision-making, and personality traits. Compare scores globally and track your progress.",
      keywords: "human benchmark, cognitive test, reaction time test, memory test, decision making, personality quiz, brain training, cognitive assessment, mental speed, attention test",
      path: "/"
    },
    reactionTime: {
      title: "Reaction Time Test - Human Benchmark",
      description: "Test your reaction time with our fast-paced cognitive test. Tap when the screen turns green and see how quick your brain really is. Compare your score with others worldwide.",
      keywords: "reaction time test, cognitive speed test, attention test, brain speed, human benchmark, reaction test",
      path: "/reaction-time"
    },
    numberMemory: {
      title: "Number Memory Test - Human Benchmark",
      description: "Challenge your memory with our number sequence test. Remember increasingly longer sequences and discover your memory capacity limits. Track your progress over time.",
      keywords: "number memory test, memory capacity test, sequence memory, cognitive memory, human benchmark, memory test",
      path: "/number-memory"
    },
    decisionMaking: {
      title: "Decision Making Test - Human Benchmark",
      description: "Test your decision-making skills under pressure. Make quick choices and see how your risk tolerance affects your performance. Compare your decision patterns with others.",
      keywords: "decision making test, risk tolerance test, cognitive decision, human benchmark, decision test, risk assessment",
      path: "/decision-making"
    },
    personalityQuiz: {
      title: "Personality Quiz - Human Benchmark",
      description: "Discover your personality traits with our comprehensive assessment. Understand your cognitive preferences and see how they relate to your test performance.",
      keywords: "personality quiz, personality test, cognitive assessment, trait analysis, human benchmark, personality assessment",
      path: "/personality-quiz"
    },
    leaderboard: {
      title: "Global Leaderboards - Human Benchmark",
      description: "Compare your cognitive test scores with players worldwide. See where you rank in reaction time, memory, decision-making, and personality traits.",
      keywords: "leaderboard, global rankings, cognitive scores, human benchmark, score comparison, world rankings",
      path: "/leaderboard"
    },
    about: {
      title: "About Human Benchmark - Cognitive Testing Platform",
      description: "Learn about Human Benchmark's mission to provide comprehensive cognitive testing tools. Understand our methodology and commitment to mental fitness.",
      keywords: "about human benchmark, cognitive testing platform, mental fitness, brain training, human benchmark mission",
      path: "/about"
    },
    features: {
      title: "Features - Human Benchmark Cognitive Testing Platform",
      description: "Explore the comprehensive features of Human Benchmark. From reaction time tests to personality assessments, discover all the ways to challenge your mind.",
      keywords: "human benchmark features, cognitive testing features, brain training tools, mental assessment features",
      path: "/features"
    }
  }
};

// Function to update meta tags dynamically
function updateMetaTags(pageKey) {
  const page = SEO_CONFIG.pages[pageKey] || SEO_CONFIG.base;
  const base = SEO_CONFIG.base;
  
  // Update title
  document.title = page.title;
  
  // Update meta tags
  updateMetaTag('name', 'title', page.title);
  updateMetaTag('name', 'description', page.description);
  updateMetaTag('name', 'keywords', page.keywords);
  updateMetaTag('name', 'author', page.author);
  
  // Update Open Graph tags
  updateMetaTag('property', 'og:title', page.title);
  updateMetaTag('property', 'og:description', page.description);
  updateMetaTag('property', 'og:url', base.url + page.path);
  updateMetaTag('property', 'og:image', page.image || base.image);
  
  // Update Twitter tags
  updateMetaTag('property', 'twitter:title', page.title);
  updateMetaTag('property', 'twitter:description', page.description);
  updateMetaTag('property', 'twitter:image', page.image || base.image);
  
  // Update canonical URL
  updateCanonicalUrl(base.url + page.path);
}

// Helper function to update meta tags
function updateMetaTag(attr, name, content) {
  let meta = document.querySelector(`meta[${attr}="${name}"]`);
  if (!meta) {
    meta = document.createElement('meta');
    meta.setAttribute(attr, name);
    document.head.appendChild(meta);
  }
  meta.setAttribute('content', content);
}

// Helper function to update canonical URL
function updateCanonicalUrl(url) {
  let canonical = document.querySelector('link[rel="canonical"]');
  if (!canonical) {
    canonical = document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    document.head.appendChild(canonical);
  }
  canonical.setAttribute('href', url);
}

// Function to update structured data
function updateStructuredData(pageKey) {
  const page = SEO_CONFIG.pages[pageKey];
  if (!page) return;
  
  // Update or create structured data script
  let script = document.querySelector('script[type="application/ld+json"]');
  if (!script) {
    script = document.createElement('script');
    script.setAttribute('type', 'application/ld+json');
    document.head.appendChild(script);
  }
  
  const structuredData = {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": page.title,
    "description": page.description,
    "url": SEO_CONFIG.base.url + page.path,
    "mainEntity": {
      "@type": "WebApplication",
      "name": "Human Benchmark",
      "applicationCategory": "Game",
      "operatingSystem": "Web Browser"
    }
  };
  
  script.textContent = JSON.stringify(structuredData);
}

// Export for use in Flutter web
if (typeof window !== 'undefined') {
  window.SEO_CONFIG = SEO_CONFIG;
  window.updateMetaTags = updateMetaTags;
  window.updateStructuredData = updateStructuredData;
}
