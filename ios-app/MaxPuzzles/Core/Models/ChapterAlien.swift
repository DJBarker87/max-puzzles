import Foundation

struct ChapterAlien: Identifiable {
    let id: Int
    let name: String
    let chapter: Int
    let imageName: String
    let words: [String]  // 3 fun words kids would like
}

extension ChapterAlien {

    static let all: [ChapterAlien] = [
        // Chapter 1 - Bob (Green blob)
        ChapterAlien(
            id: 1,
            name: "Bob",
            chapter: 1,
            imageName: "alien_bob",
            words: ["Squishy", "Bouncy", "Friendly"]
        ),

        // Chapter 2 - Blink (Blue tall alien)
        ChapterAlien(
            id: 2,
            name: "Blink",
            chapter: 2,
            imageName: "alien_blink",
            words: ["Wobbly", "Wavy", "Giggly"]
        ),

        // Chapter 3 - Drift (Purple jellyfish)
        ChapterAlien(
            id: 3,
            name: "Drift",
            chapter: 3,
            imageName: "alien_drift",
            words: ["Floaty", "Glowy", "Slimy"]
        ),

        // Chapter 4 - Fuzz (Orange furry)
        ChapterAlien(
            id: 4,
            name: "Fuzz",
            chapter: 4,
            imageName: "alien_fuzz",
            words: ["Fluffy", "Crazy", "Ticklish"]
        ),

        // Chapter 5 - Prism (Pink crystal)
        ChapterAlien(
            id: 5,
            name: "Prism",
            chapter: 5,
            imageName: "alien_prism",
            words: ["Sparkly", "Shiny", "Magical"]
        ),

        // Chapter 6 - Nova (Yellow star)
        ChapterAlien(
            id: 6,
            name: "Nova",
            chapter: 6,
            imageName: "alien_nova",
            words: ["Glowing", "Warm", "Giggly"]
        ),

        // Chapter 7 - Clicker (Red crab)
        ChapterAlien(
            id: 7,
            name: "Clicker",
            chapter: 7,
            imageName: "alien_clicker",
            words: ["Snappy", "Crunchy", "Cheeky"]
        ),

        // Chapter 8 - Bolt (Teal robot)
        ChapterAlien(
            id: 8,
            name: "Bolt",
            chapter: 8,
            imageName: "alien_bolt",
            words: ["Beepy", "Zippy", "Brainy"]
        ),

        // Chapter 9 - Sage (Silver elegant)
        ChapterAlien(
            id: 9,
            name: "Sage",
            chapter: 9,
            imageName: "alien_sage",
            words: ["Mysterious", "Flowy", "Ancient"]
        ),

        // Chapter 10 - Bibomic (Golden champion)
        ChapterAlien(
            id: 10,
            name: "Bibomic",
            chapter: 10,
            imageName: "alien_bibomic",
            words: ["Legendary", "Golden", "Ultimate"]
        )
    ]

    static func forChapter(_ chapter: Int) -> ChapterAlien? {
        all.first { $0.chapter == chapter }
    }
}
