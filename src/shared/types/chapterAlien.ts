export interface ChapterAlien {
  id: number;
  name: string;
  chapter: number;
  imagePath: string;
  words: [string, string, string]; // 3 fun words kids would like
  introMessages: [string, string, string, string, string]; // 5 unique good luck messages
}

/** Get a random intro message for an alien */
export function getRandomIntroMessage(alien: ChapterAlien): string {
  return alien.introMessages[Math.floor(Math.random() * alien.introMessages.length)];
}

export const chapterAliens: ChapterAlien[] = [
  // Chapter 1 - Bob (Green blob) - Squishy, Bouncy, Friendly
  {
    id: 1,
    name: "Bob",
    chapter: 1,
    imagePath: "/aliens/alien_bob.png",
    words: ["Squishy", "Bouncy", "Friendly"],
    introMessages: [
      "Boing! Let's bounce through this!",
      "Squish squash, you've got this!",
      "I believe in you, friend!",
      "Ready to bounce to victory?",
      "Let's squish this puzzle together!",
    ],
  },

  // Chapter 2 - Blink (Blue tall alien) - Wobbly, Wavy, Giggly
  {
    id: 2,
    name: "Blink",
    chapter: 2,
    imagePath: "/aliens/alien_blink.png",
    words: ["Wobbly", "Wavy", "Giggly"],
    introMessages: [
      "Hehe! This is gonna be fun!",
      "Wobble wobble, let's go!",
      "Wave hello to victory!",
      "Giggle time! You can do it!",
      "Let's wiggle through this one!",
    ],
  },

  // Chapter 3 - Drift (Purple jellyfish) - Floaty, Glowy, Slimy
  {
    id: 3,
    name: "Drift",
    chapter: 3,
    imagePath: "/aliens/alien_drift.png",
    words: ["Floaty", "Glowy", "Slimy"],
    introMessages: [
      "Float with me to the finish!",
      "Let your brain glow bright!",
      "Drift through this puzzle smoothly!",
      "Shine on, puzzle master!",
      "Glide along the right path!",
    ],
  },

  // Chapter 4 - Fuzz (Orange furry) - Fluffy, Crazy, Ticklish
  {
    id: 4,
    name: "Fuzz",
    chapter: 4,
    imagePath: "/aliens/alien_fuzz.png",
    words: ["Fluffy", "Crazy", "Ticklish"],
    introMessages: [
      "Fluff yeah! Let's do this!",
      "This is gonna be crazy fun!",
      "Tickle those brain cells!",
      "Get fuzzy with it!",
      "Wild and fluffy, here we go!",
    ],
  },

  // Chapter 5 - Prism (Pink crystal) - Sparkly, Shiny, Magical
  {
    id: 5,
    name: "Prism",
    chapter: 5,
    imagePath: "/aliens/alien_prism.png",
    words: ["Sparkly", "Shiny", "Magical"],
    introMessages: [
      "Sparkle your way to victory!",
      "Make some magic happen!",
      "Shine bright like a crystal!",
      "Your brain is sparkling today!",
      "Time for some shiny problem solving!",
    ],
  },

  // Chapter 6 - Nova (Yellow star) - Glowing, Warm, Giggly
  {
    id: 6,
    name: "Nova",
    chapter: 6,
    imagePath: "/aliens/alien_nova.png",
    words: ["Glowing", "Warm", "Giggly"],
    introMessages: [
      "Let's light up this puzzle!",
      "Warm wishes for a great solve!",
      "Glow for it, superstar!",
      "Tee-hee! You're gonna shine!",
      "Radiate that brain power!",
    ],
  },

  // Chapter 7 - Clicker (Red crab) - Snappy, Crunchy, Cheeky
  {
    id: 7,
    name: "Clicker",
    chapter: 7,
    imagePath: "/aliens/alien_clicker.png",
    words: ["Snappy", "Crunchy", "Cheeky"],
    introMessages: [
      "Click click! Let's get snappy!",
      "Crunch those numbers, friend!",
      "Snap to it, puzzle solver!",
      "Feeling cheeky? Let's win this!",
      "Pinch this puzzle into shape!",
    ],
  },

  // Chapter 8 - Bolt (Teal robot) - Beepy, Zippy, Brainy
  {
    id: 8,
    name: "Bolt",
    chapter: 8,
    imagePath: "/aliens/alien_bolt.png",
    words: ["Beepy", "Zippy", "Brainy"],
    introMessages: [
      "Beep boop! Calculating success!",
      "Zip through this at lightning speed!",
      "Engage brainy mode!",
      "Processing... You will win!",
      "Zap! Power up that brain!",
    ],
  },

  // Chapter 9 - Sage (Silver elegant) - Mysterious, Flowy, Ancient
  {
    id: 9,
    name: "Sage",
    chapter: 9,
    imagePath: "/aliens/alien_sage.png",
    words: ["Mysterious", "Flowy", "Ancient"],
    introMessages: [
      "The ancient wisdom flows through you.",
      "Mystery awaits... embrace it.",
      "Let knowledge flow like water.",
      "Wise one, the path reveals itself.",
      "Ancient secrets guide your way.",
    ],
  },

  // Chapter 10 - Bibomic (Golden champion) - Legendary, Golden, Ultimate
  {
    id: 10,
    name: "Bibomic",
    chapter: 10,
    imagePath: "/aliens/alien_bibomic.png",
    words: ["Legendary", "Golden", "Ultimate"],
    introMessages: [
      "Legends are made here!",
      "Go for gold, champion!",
      "This is your ultimate moment!",
      "Legendary solver, show your power!",
      "The golden victory awaits you!",
    ],
  },
];

export function getAlienForChapter(chapter: number): ChapterAlien | undefined {
  return chapterAliens.find((alien) => alien.chapter === chapter);
}
