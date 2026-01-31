import Foundation

struct ChapterAlien: Identifiable {
    let id: Int
    let name: String
    let chapter: Int
    let imageName: String
    let words: [String]  // 3 fun words kids would like
    let introMessages: [String]  // 5 unique good luck messages
    let winMessages: [String]  // 5 unique congratulatory messages

    /// Get a random intro message for level start
    var randomIntroMessage: String {
        introMessages.randomElement() ?? "Good luck!"
    }

    /// Get a random win message for level complete
    var randomWinMessage: String {
        winMessages.randomElement() ?? "Great job!"
    }

    /// Get a personalized intro message with player name
    func personalizedIntroMessage(playerName: String) -> String {
        let baseMessage = randomIntroMessage
        if playerName.isEmpty {
            return baseMessage
        }
        // Add personalization to some messages
        let personalizedPrefixes = [
            "Hey \(playerName)! ",
            "\(playerName), ",
            "Alright \(playerName)! ",
            "Come on \(playerName)! ",
            "\(playerName)! "
        ]
        let prefix = personalizedPrefixes.randomElement() ?? ""
        return prefix + baseMessage
    }

    /// Get a personalized win message with player name
    func personalizedWinMessage(playerName: String) -> String {
        let baseMessage = randomWinMessage
        if playerName.isEmpty {
            return baseMessage
        }
        // Add personalization
        let personalizedSuffixes = [
            " Way to go, \(playerName)!",
            " \(playerName), you're amazing!",
            " Fantastic work, \(playerName)!",
            " You rock, \(playerName)!",
            ""
        ]
        let suffix = personalizedSuffixes.randomElement() ?? ""
        return baseMessage + suffix
    }

    /// Get a hidden mode intro message for level 7 (center tile - hidden mode)
    func hiddenModeIntro(playerName: String) -> String {
        let prefix = playerName.isEmpty ? "" : "\(playerName), "
        return "\(prefix)this is Hidden Mode! You won't see if you're right or wrong until the end. Think carefully!"
    }
}

extension ChapterAlien {

    /// Default fallback alien in case array is empty
    static let defaultAlien = ChapterAlien(
        id: 0,
        name: "Cosmo",
        chapter: 0,
        imageName: "alien_bob",  // Use Bob's image as fallback
        words: ["Friendly", "Helpful", "Fun"],
        introMessages: ["Let's do this!", "Good luck!", "You've got this!"],
        winMessages: ["Great job!", "Amazing!", "You did it!"]
    )

    static let all: [ChapterAlien] = [
        // Chapter 1 - Bob (Green blob) - Squishy, Bouncy, Friendly
        ChapterAlien(
            id: 1,
            name: "Bob",
            chapter: 1,
            imageName: "alien_bob",
            words: ["Squishy", "Bouncy", "Friendly"],
            introMessages: [
                "Boing! Let's bounce through this!",
                "Squish squash, you've got this!",
                "I believe in you, friend!",
                "Ready to bounce to victory?",
                "Let's squish this puzzle together!"
            ],
            winMessages: [
                "Boing boing! You bounced right through it!",
                "Squishy hugs for my clever friend!",
                "You did it! I'm bouncing with joy!",
                "Squish-tastic work, buddy!",
                "My bouncy heart is so happy for you!"
            ]
        ),

        // Chapter 2 - Blink (Blue tall alien) - Wobbly, Wavy, Giggly
        ChapterAlien(
            id: 2,
            name: "Blink",
            chapter: 2,
            imageName: "alien_blink",
            words: ["Wobbly", "Wavy", "Giggly"],
            introMessages: [
                "Hehe! This is gonna be fun!",
                "Wobble wobble, let's go!",
                "Wave hello to victory!",
                "Giggle time! You can do it!",
                "Let's wiggle through this one!"
            ],
            winMessages: [
                "Hehehe! You're so clever!",
                "Wobbly-wonderful work!",
                "I'm giggling with happiness!",
                "You made me wiggle with joy!",
                "Wavy high-five for the win!"
            ]
        ),

        // Chapter 3 - Drift (Purple jellyfish) - Floaty, Glowy, Slimy
        ChapterAlien(
            id: 3,
            name: "Drift",
            chapter: 3,
            imageName: "alien_drift",
            words: ["Floaty", "Glowy", "Slimy"],
            introMessages: [
                "Float with me to the finish!",
                "Let your brain glow bright!",
                "Drift through this puzzle smoothly!",
                "Shine on, puzzle master!",
                "Glide along the right path!"
            ],
            winMessages: [
                "You floated through beautifully...",
                "Your mind glows so bright!",
                "Drifting to victory... lovely.",
                "You shine like the stars above.",
                "Smooth as slime, well done."
            ]
        ),

        // Chapter 4 - Fuzz (Orange furry) - Fluffy, Crazy, Ticklish
        ChapterAlien(
            id: 4,
            name: "Fuzz",
            chapter: 4,
            imageName: "alien_fuzz",
            words: ["Fluffy", "Crazy", "Ticklish"],
            introMessages: [
                "Fluff yeah! Let's do this!",
                "This is gonna be crazy fun!",
                "Tickle those brain cells!",
                "Get fuzzy with it!",
                "Wild and fluffy, here we go!"
            ],
            winMessages: [
                "FLUFF YEAH! You did it!",
                "That was crazy awesome!",
                "You tickled that puzzle into submission!",
                "Fuzzy high-five! Amazing!",
                "Wild! Incredible! FLUFFY!"
            ]
        ),

        // Chapter 5 - Prism (Pink crystal) - Sparkly, Shiny, Magical
        ChapterAlien(
            id: 5,
            name: "Prism",
            chapter: 5,
            imageName: "alien_prism",
            words: ["Sparkly", "Shiny", "Magical"],
            introMessages: [
                "Sparkle your way to victory!",
                "Make some magic happen!",
                "Shine bright like a crystal!",
                "Your brain is sparkling today!",
                "Time for some shiny problem solving!"
            ],
            winMessages: [
                "You sparkled magnificently!",
                "Pure magic! Simply dazzling!",
                "You shine brighter than any crystal!",
                "What a sparkling performance!",
                "Magical! Truly magical!"
            ]
        ),

        // Chapter 6 - Nova (Yellow star) - Glowing, Warm, Giggly
        ChapterAlien(
            id: 6,
            name: "Nova",
            chapter: 6,
            imageName: "alien_nova",
            words: ["Glowing", "Warm", "Giggly"],
            introMessages: [
                "Let's light up this puzzle!",
                "Warm wishes for a great solve!",
                "Glow for it, superstar!",
                "Tee-hee! You're gonna shine!",
                "Radiate that brain power!"
            ],
            winMessages: [
                "You lit up the whole puzzle!",
                "Warm fuzzy feelings for you!",
                "Tee-hee! You're a superstar!",
                "You radiated pure brilliance!",
                "Glowing with pride for you!"
            ]
        ),

        // Chapter 7 - Clicker (Red crab) - Snappy, Crunchy, Cheeky
        ChapterAlien(
            id: 7,
            name: "Clicker",
            chapter: 7,
            imageName: "alien_clicker",
            words: ["Snappy", "Crunchy", "Cheeky"],
            introMessages: [
                "Click click! Let's get snappy!",
                "Crunch those numbers, friend!",
                "Snap to it, puzzle solver!",
                "Feeling cheeky? Let's win this!",
                "Pinch this puzzle into shape!"
            ],
            winMessages: [
                "Click click! Snappy work!",
                "You crunched it perfectly!",
                "Now THAT'S what I call cheeky genius!",
                "Pinch me, that was amazing!",
                "Snap snap snap! Victory claps!"
            ]
        ),

        // Chapter 8 - Bolt (Teal robot) - Beepy, Zippy, Brainy
        ChapterAlien(
            id: 8,
            name: "Bolt",
            chapter: 8,
            imageName: "alien_bolt",
            words: ["Beepy", "Zippy", "Brainy"],
            introMessages: [
                "Beep boop! Calculating success!",
                "Zip through this at lightning speed!",
                "Engage brainy mode!",
                "Processing... You will win!",
                "Zap! Power up that brain!"
            ],
            winMessages: [
                "BEEP BOOP! Success confirmed!",
                "Zip zap! Lightning fast solve!",
                "Brain power at maximum! Well done!",
                "Processing complete: You are awesome!",
                "Zzzap! Electrifying performance!"
            ]
        ),

        // Chapter 9 - Sage (Silver elegant) - Mysterious, Flowy, Ancient
        ChapterAlien(
            id: 9,
            name: "Sage",
            chapter: 9,
            imageName: "alien_sage",
            words: ["Mysterious", "Flowy", "Ancient"],
            introMessages: [
                "The ancient wisdom flows through you.",
                "Mystery awaits... embrace it.",
                "Let knowledge flow like water.",
                "Wise one, the path reveals itself.",
                "Ancient secrets guide your way."
            ],
            winMessages: [
                "The wisdom within you shines bright.",
                "Mysterious and magnificent...",
                "The ancients would be proud.",
                "Your mind flows like a gentle river.",
                "Enlightenment achieved, wise one."
            ]
        ),

        // Chapter 10 - Bibomic (Golden champion) - Legendary, Golden, Ultimate
        ChapterAlien(
            id: 10,
            name: "Bibomic",
            chapter: 10,
            imageName: "alien_bibomic",
            words: ["Legendary", "Golden", "Ultimate"],
            introMessages: [
                "Legends are made here!",
                "Go for gold, champion!",
                "This is your ultimate moment!",
                "Legendary solver, show your power!",
                "The golden victory awaits you!"
            ],
            winMessages: [
                "LEGENDARY! A true champion!",
                "Golden perfection! You're incredible!",
                "The ultimate victory is yours!",
                "A legend has been born today!",
                "Pure gold! Absolutely magnificent!"
            ]
        )
    ]

    static func forChapter(_ chapter: Int) -> ChapterAlien? {
        all.first { $0.chapter == chapter }
    }
}
