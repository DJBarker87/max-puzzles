export interface ChapterAlien {
  id: number;
  name: string;
  chapter: number;
  imagePath: string;
  words: [string, string, string]; // 3 fun words kids would like
  introMessages: [string, string, string, string, string]; // 5 unique good luck messages
  winMessages: [string, string, string, string, string]; // 5 unique congratulatory messages
}

/** Get a random intro message for an alien */
export function getRandomIntroMessage(alien: ChapterAlien): string {
  return alien.introMessages[Math.floor(Math.random() * alien.introMessages.length)];
}

/** Get a random win message for an alien */
export function getRandomWinMessage(alien: ChapterAlien): string {
  return alien.winMessages[Math.floor(Math.random() * alien.winMessages.length)];
}

export const chapterAliens: ChapterAlien[] = [
  // Chapter 1 - Bob (Green blob) - Squishy, Bouncy, Friendly
  {
    id: 1,
    name: "Bob",
    chapter: 1,
    imagePath: "/Aliens/alien_bob.png",
    words: ["Squishy", "Bouncy", "Friendly"],
    introMessages: [
      "Boing! Let's bounce through this!",
      "Squish squash, you've got this!",
      "I believe in you, friend!",
      "Ready to bounce to victory?",
      "Let's squish this puzzle together!",
    ],
    winMessages: [
      "Boing boing! You bounced right through it!",
      "Squishy hugs for my clever friend!",
      "You did it! I'm bouncing with joy!",
      "Squish-tastic work, buddy!",
      "My bouncy heart is so happy for you!",
    ],
  },

  // Chapter 2 - Blink (Blue tall alien) - Wobbly, Wavy, Giggly
  {
    id: 2,
    name: "Blink",
    chapter: 2,
    imagePath: "/Aliens/alien_blink.png",
    words: ["Wobbly", "Wavy", "Giggly"],
    introMessages: [
      "Hehe! This is gonna be fun!",
      "Wobble wobble, let's go!",
      "Wave hello to victory!",
      "Giggle time! You can do it!",
      "Let's wiggle through this one!",
    ],
    winMessages: [
      "Hehehe! You're so clever!",
      "Wobbly-wonderful work!",
      "I'm giggling with happiness!",
      "You made me wiggle with joy!",
      "Wavy high-five for the win!",
    ],
  },

  // Chapter 3 - Drift (Purple jellyfish) - Floaty, Glowy, Slimy
  {
    id: 3,
    name: "Drift",
    chapter: 3,
    imagePath: "/Aliens/alien_drift.png",
    words: ["Floaty", "Glowy", "Slimy"],
    introMessages: [
      "Float with me to the finish!",
      "Let your brain glow bright!",
      "Drift through this puzzle smoothly!",
      "Shine on, puzzle master!",
      "Glide along the right path!",
    ],
    winMessages: [
      "You floated through beautifully...",
      "Your mind glows so bright!",
      "Drifting to victory... lovely.",
      "You shine like the stars above.",
      "Smooth as slime, well done.",
    ],
  },

  // Chapter 4 - Fuzz (Orange furry) - Fluffy, Crazy, Ticklish
  {
    id: 4,
    name: "Fuzz",
    chapter: 4,
    imagePath: "/Aliens/alien_fuzz.png",
    words: ["Fluffy", "Crazy", "Ticklish"],
    introMessages: [
      "Fluff yeah! Let's do this!",
      "This is gonna be crazy fun!",
      "Tickle those brain cells!",
      "Get fuzzy with it!",
      "Wild and fluffy, here we go!",
    ],
    winMessages: [
      "FLUFF YEAH! You did it!",
      "That was crazy awesome!",
      "You tickled that puzzle into submission!",
      "Fuzzy high-five! Amazing!",
      "Wild! Incredible! FLUFFY!",
    ],
  },

  // Chapter 5 - Prism (Pink crystal) - Sparkly, Shiny, Magical
  {
    id: 5,
    name: "Prism",
    chapter: 5,
    imagePath: "/Aliens/alien_prism.png",
    words: ["Sparkly", "Shiny", "Magical"],
    introMessages: [
      "Sparkle your way to victory!",
      "Make some magic happen!",
      "Shine bright like a crystal!",
      "Your brain is sparkling today!",
      "Time for some shiny problem solving!",
    ],
    winMessages: [
      "You sparkled magnificently!",
      "Pure magic! Simply dazzling!",
      "You shine brighter than any crystal!",
      "What a sparkling performance!",
      "Magical! Truly magical!",
    ],
  },

  // Chapter 6 - Nova (Yellow star) - Glowing, Warm, Giggly
  {
    id: 6,
    name: "Nova",
    chapter: 6,
    imagePath: "/Aliens/alien_nova.png",
    words: ["Glowing", "Warm", "Giggly"],
    introMessages: [
      "Let's light up this puzzle!",
      "Warm wishes for a great solve!",
      "Glow for it, superstar!",
      "Tee-hee! You're gonna shine!",
      "Radiate that brain power!",
    ],
    winMessages: [
      "You lit up the whole puzzle!",
      "Warm fuzzy feelings for you!",
      "Tee-hee! You're a superstar!",
      "You radiated pure brilliance!",
      "Glowing with pride for you!",
    ],
  },

  // Chapter 7 - Clicker (Red crab) - Snappy, Crunchy, Cheeky
  {
    id: 7,
    name: "Clicker",
    chapter: 7,
    imagePath: "/Aliens/alien_clicker.png",
    words: ["Snappy", "Crunchy", "Cheeky"],
    introMessages: [
      "Click click! Let's get snappy!",
      "Crunch those numbers, friend!",
      "Snap to it, puzzle solver!",
      "Feeling cheeky? Let's win this!",
      "Pinch this puzzle into shape!",
    ],
    winMessages: [
      "Click click! Snappy work!",
      "You crunched it perfectly!",
      "Now THAT'S what I call cheeky genius!",
      "Pinch me, that was amazing!",
      "Snap snap snap! Victory claps!",
    ],
  },

  // Chapter 8 - Bolt (Teal robot) - Beepy, Zippy, Brainy
  {
    id: 8,
    name: "Bolt",
    chapter: 8,
    imagePath: "/Aliens/alien_bolt.png",
    words: ["Beepy", "Zippy", "Brainy"],
    introMessages: [
      "Beep boop! Calculating success!",
      "Zip through this at lightning speed!",
      "Engage brainy mode!",
      "Processing... You will win!",
      "Zap! Power up that brain!",
    ],
    winMessages: [
      "BEEP BOOP! Success confirmed!",
      "Zip zap! Lightning fast solve!",
      "Brain power at maximum! Well done!",
      "Processing complete: You are awesome!",
      "Zzzap! Electrifying performance!",
    ],
  },

  // Chapter 9 - Sage (Silver elegant) - Mysterious, Flowy, Ancient
  {
    id: 9,
    name: "Sage",
    chapter: 9,
    imagePath: "/Aliens/alien_sage.png",
    words: ["Mysterious", "Flowy", "Ancient"],
    introMessages: [
      "The ancient wisdom flows through you.",
      "Mystery awaits... embrace it.",
      "Let knowledge flow like water.",
      "Wise one, the path reveals itself.",
      "Ancient secrets guide your way.",
    ],
    winMessages: [
      "The wisdom within you shines bright.",
      "Mysterious and magnificent...",
      "The ancients would be proud.",
      "Your mind flows like a gentle river.",
      "Enlightenment achieved, wise one.",
    ],
  },

  // Chapter 10 - Bibomic (Golden champion) - Legendary, Golden, Ultimate
  {
    id: 10,
    name: "Bibomic",
    chapter: 10,
    imagePath: "/Aliens/alien_bibomic.png",
    words: ["Legendary", "Golden", "Ultimate"],
    introMessages: [
      "Legends are made here!",
      "Go for gold, champion!",
      "This is your ultimate moment!",
      "Legendary solver, show your power!",
      "The golden victory awaits you!",
    ],
    winMessages: [
      "LEGENDARY! A true champion!",
      "Golden perfection! You're incredible!",
      "The ultimate victory is yours!",
      "A legend has been born today!",
      "Pure gold! Absolutely magnificent!",
    ],
  },
];

export function getAlienForChapter(chapter: number): ChapterAlien | undefined {
  return chapterAliens.find((alien) => alien.chapter === chapter);
}
