export interface ChapterAlien {
  id: number;
  name: string;
  chapter: number;
  imagePath: string;
  words: [string, string, string]; // 3 fun words kids would like
}

export const chapterAliens: ChapterAlien[] = [
  // Chapter 1 - Bob (Green blob)
  {
    id: 1,
    name: "Bob",
    chapter: 1,
    imagePath: "/aliens/alien_bob.png",
    words: ["Squishy", "Bouncy", "Friendly"],
  },

  // Chapter 2 - Blink (Blue tall alien)
  {
    id: 2,
    name: "Blink",
    chapter: 2,
    imagePath: "/aliens/alien_blink.png",
    words: ["Wobbly", "Wavy", "Giggly"],
  },

  // Chapter 3 - Drift (Purple jellyfish)
  {
    id: 3,
    name: "Drift",
    chapter: 3,
    imagePath: "/aliens/alien_drift.png",
    words: ["Floaty", "Glowy", "Slimy"],
  },

  // Chapter 4 - Fuzz (Orange furry)
  {
    id: 4,
    name: "Fuzz",
    chapter: 4,
    imagePath: "/aliens/alien_fuzz.png",
    words: ["Fluffy", "Crazy", "Ticklish"],
  },

  // Chapter 5 - Prism (Pink crystal)
  {
    id: 5,
    name: "Prism",
    chapter: 5,
    imagePath: "/aliens/alien_prism.png",
    words: ["Sparkly", "Shiny", "Magical"],
  },

  // Chapter 6 - Nova (Yellow star)
  {
    id: 6,
    name: "Nova",
    chapter: 6,
    imagePath: "/aliens/alien_nova.png",
    words: ["Glowing", "Warm", "Giggly"],
  },

  // Chapter 7 - Clicker (Red crab)
  {
    id: 7,
    name: "Clicker",
    chapter: 7,
    imagePath: "/aliens/alien_clicker.png",
    words: ["Snappy", "Crunchy", "Cheeky"],
  },

  // Chapter 8 - Bolt (Teal robot)
  {
    id: 8,
    name: "Bolt",
    chapter: 8,
    imagePath: "/aliens/alien_bolt.png",
    words: ["Beepy", "Zippy", "Brainy"],
  },

  // Chapter 9 - Sage (Silver elegant)
  {
    id: 9,
    name: "Sage",
    chapter: 9,
    imagePath: "/aliens/alien_sage.png",
    words: ["Mysterious", "Flowy", "Ancient"],
  },

  // Chapter 10 - Bibomic (Golden champion)
  {
    id: 10,
    name: "Bibomic",
    chapter: 10,
    imagePath: "/aliens/alien_bibomic.png",
    words: ["Legendary", "Golden", "Ultimate"],
  },
];

export function getAlienForChapter(chapter: number): ChapterAlien | undefined {
  return chapterAliens.find((alien) => alien.chapter === chapter);
}
