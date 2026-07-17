import SwiftUI

extension DotPuzzleCatalog {
    /// Eighty-four distinct pictures visible across d1–d7. D1 and D2 contain the same contact
    /// sheet, so those fifteen designs intentionally appear once rather than as duplicate games.
    static let downloadedReferencePuzzles: [DotPuzzle] = DownloadedDotPuzzlePack.build()
}

private enum DownloadedDotPuzzlePack {
    private struct Spec {
        let sheet: String
        let slot: Int
        let title: String
        let emoji: String
        let tier: DotToDotTier
        let palette: DotPuzzlePalette
        /// Kept in the durable ID so progress for the current 84 pictures remains stable.
        let template: String
    }

    static func build() -> [DotPuzzle] {
        specs.map { spec in
            let idSlot = spec.slot < 10 ? "0\(spec.slot)" : "\(spec.slot)"
            let sheetID = spec.sheet.lowercased().replacingOccurrences(of: "/", with: "-")
            let puzzleID = "reference-\(sheetID)-\(idSlot)-\(spec.template)"
            let trail = DownloadedDotPuzzleArtwork.trail(
                sheet: spec.sheet,
                slot: spec.slot,
                expectedCount: spec.tier.maxNumeral
            )
            let referenceArt = DownloadedDotPuzzleArtwork.referenceArt(
                sheet: spec.sheet,
                slot: spec.slot
            )

            precondition(
                trail.count == spec.tier.maxNumeral,
                "Missing extracted trail for \(puzzleID)"
            )
            precondition(referenceArt != nil, "Missing downloaded artwork for \(puzzleID)")

            return DotPuzzle(
                id: puzzleID,
                title: spec.title,
                emoji: spec.emoji,
                tier: spec.tier,
                palette: spec.palette,
                outline: trail,
                trail: trail,
                sourceSheet: spec.sheet,
                referenceArt: referenceArt
            )
        }
    }

    // MARK: - Contact-sheet inventory

    private static let specs: [Spec] = [
        // d1 and d2 are byte-for-byte-equivalent artwork sheets.
        .init(sheet: "D1/D2", slot: 1, title: "Giraffe", emoji: "🦒", tier: .numberExplorer, palette: .gold, template: "giraffe"),
        .init(sheet: "D1/D2", slot: 2, title: "Sailboat", emoji: "⛵️", tier: .numberTrail, palette: .sky, template: "sailboat"),
        .init(sheet: "D1/D2", slot: 3, title: "Octopus", emoji: "🐙", tier: .numberExplorer, palette: .violet, template: "octopus"),
        .init(sheet: "D1/D2", slot: 4, title: "Rocket", emoji: "🚀", tier: .numberTrail, palette: .coral, template: "rocket"),
        .init(sheet: "D1/D2", slot: 5, title: "Tiger", emoji: "🐯", tier: .numberTrail, palette: .gold, template: "tiger"),
        .init(sheet: "D1/D2", slot: 6, title: "Submarine", emoji: "🛟", tier: .numberExplorer, palette: .gold, template: "submarine"),
        .init(sheet: "D1/D2", slot: 7, title: "Hamster", emoji: "🐹", tier: .numberTrail, palette: .coral, template: "hamster"),
        .init(sheet: "D1/D2", slot: 8, title: "Ocean Ship", emoji: "🚢", tier: .bigNumberAdventure, palette: .sky, template: "pirate-ship"),
        .init(sheet: "D1/D2", slot: 9, title: "Bumblebee", emoji: "🐝", tier: .numberTrail, palette: .gold, template: "bee"),
        .init(sheet: "D1/D2", slot: 10, title: "Helicopter", emoji: "🚁", tier: .numberExplorer, palette: .sky, template: "helicopter"),
        .init(sheet: "D1/D2", slot: 11, title: "Dump Truck", emoji: "🚚", tier: .bigNumberAdventure, palette: .gold, template: "dump-truck"),
        .init(sheet: "D1/D2", slot: 12, title: "Steam Train", emoji: "🚂", tier: .numberExplorer, palette: .coral, template: "train"),
        .init(sheet: "D1/D2", slot: 13, title: "Tractor", emoji: "🚜", tier: .numberExplorer, palette: .lime, template: "tractor"),
        .init(sheet: "D1/D2", slot: 14, title: "Aeroplane", emoji: "✈️", tier: .numberExplorer, palette: .sky, template: "airplane"),
        .init(sheet: "D1/D2", slot: 15, title: "Bus", emoji: "🚌", tier: .numberExplorer, palette: .coral, template: "bus"),

        .init(sheet: "D3", slot: 1, title: "Stingray", emoji: "🌊", tier: .numberExplorer, palette: .aqua, template: "stingray"),
        .init(sheet: "D3", slot: 2, title: "Elephant", emoji: "🐘", tier: .numberExplorer, palette: .violet, template: "elephant"),
        .init(sheet: "D3", slot: 3, title: "Whale", emoji: "🐋", tier: .numberExplorer, palette: .sky, template: "whale"),
        .init(sheet: "D3", slot: 4, title: "Tapir", emoji: "🦣", tier: .numberExplorer, palette: .aqua, template: "tapir"),
        .init(sheet: "D3", slot: 5, title: "Scooter", emoji: "🛵", tier: .bigNumberAdventure, palette: .coral, template: "scooter"),
        .init(sheet: "D3", slot: 6, title: "Pelican", emoji: "🐦", tier: .numberTrail, palette: .gold, template: "pelican"),
        .init(sheet: "D3", slot: 7, title: "Ostrich", emoji: "🐦", tier: .numberExplorer, palette: .coral, template: "ostrich"),
        .init(sheet: "D3", slot: 8, title: "Fox", emoji: "🦊", tier: .numberTrail, palette: .coral, template: "fox"),
        .init(sheet: "D3", slot: 9, title: "Farm Tractor", emoji: "🚜", tier: .bigNumberAdventure, palette: .lime, template: "tractor"),
        .init(sheet: "D3", slot: 10, title: "Lion", emoji: "🦁", tier: .numberExplorer, palette: .gold, template: "lion"),
        .init(sheet: "D3", slot: 11, title: "Jellyfish", emoji: "🪼", tier: .numberTrail, palette: .violet, template: "jellyfish"),
        .init(sheet: "D3", slot: 12, title: "Turtle", emoji: "🐢", tier: .numberTrail, palette: .lime, template: "turtle"),
        .init(sheet: "D3", slot: 13, title: "Shark", emoji: "🦈", tier: .numberExplorer, palette: .aqua, template: "shark"),
        .init(sheet: "D3", slot: 14, title: "Monkey", emoji: "🐒", tier: .numberTrail, palette: .gold, template: "monkey"),
        .init(sheet: "D3", slot: 15, title: "Llama", emoji: "🦙", tier: .numberExplorer, palette: .violet, template: "llama"),

        .init(sheet: "D4", slot: 1, title: "Cow", emoji: "🐮", tier: .numberTrail, palette: .aqua, template: "cow"),
        .init(sheet: "D4", slot: 2, title: "Koala", emoji: "🐨", tier: .numberTrail, palette: .aqua, template: "koala"),
        .init(sheet: "D4", slot: 3, title: "Dancing Octopus", emoji: "🐙", tier: .numberExplorer, palette: .violet, template: "octopus"),
        .init(sheet: "D4", slot: 4, title: "Little Fish", emoji: "🐟", tier: .numberTrail, palette: .sky, template: "fish"),
        .init(sheet: "D4", slot: 5, title: "Walrus", emoji: "🦭", tier: .numberExplorer, palette: .aqua, template: "walrus"),
        .init(sheet: "D4", slot: 6, title: "Hedgehog", emoji: "🦔", tier: .numberTrail, palette: .gold, template: "hedgehog"),
        .init(sheet: "D4", slot: 7, title: "Pearl Shell", emoji: "🐚", tier: .numberTrail, palette: .coral, template: "shell"),
        .init(sheet: "D4", slot: 8, title: "Tropical Island", emoji: "🏝️", tier: .numberExplorer, palette: .lime, template: "tropical-island"),
        .init(sheet: "D4", slot: 9, title: "Owl", emoji: "🦉", tier: .numberTrail, palette: .violet, template: "owl"),
        .init(sheet: "D4", slot: 10, title: "Frog", emoji: "🐸", tier: .numberTrail, palette: .lime, template: "frog"),
        .init(sheet: "D4", slot: 11, title: "Rooster", emoji: "🐓", tier: .numberTrail, palette: .coral, template: "rooster"),
        .init(sheet: "D4", slot: 12, title: "Duckling", emoji: "🐥", tier: .numberTrail, palette: .gold, template: "duck"),
        .init(sheet: "D4", slot: 13, title: "Pineapple", emoji: "🍍", tier: .numberTrail, palette: .gold, template: "pineapple"),
        .init(sheet: "D4", slot: 14, title: "Broccoli", emoji: "🥦", tier: .numberTrail, palette: .lime, template: "broccoli"),
        .init(sheet: "D4", slot: 15, title: "Crocodile", emoji: "🐊", tier: .numberExplorer, palette: .lime, template: "crocodile"),

        .init(sheet: "D5", slot: 1, title: "Anteater", emoji: "🐾", tier: .numberExplorer, palette: .aqua, template: "anteater"),
        .init(sheet: "D5", slot: 2, title: "Mouse", emoji: "🐭", tier: .numberTrail, palette: .aqua, template: "mouse"),
        .init(sheet: "D5", slot: 3, title: "Cherries", emoji: "🍒", tier: .firstDots, palette: .coral, template: "cherries"),
        .init(sheet: "D5", slot: 4, title: "Pig", emoji: "🐷", tier: .numberTrail, palette: .coral, template: "pig"),
        .init(sheet: "D5", slot: 5, title: "Red Panda", emoji: "🐾", tier: .numberTrail, palette: .coral, template: "red-panda"),
        .init(sheet: "D5", slot: 6, title: "Helping Hand", emoji: "✋", tier: .numberExplorer, palette: .gold, template: "hand"),
        .init(sheet: "D5", slot: 7, title: "Raccoon", emoji: "🦝", tier: .numberTrail, palette: .aqua, template: "raccoon"),
        .init(sheet: "D5", slot: 8, title: "Grasshopper", emoji: "🦗", tier: .numberExplorer, palette: .lime, template: "grasshopper"),
        .init(sheet: "D5", slot: 9, title: "Butterfly", emoji: "🦋", tier: .numberTrail, palette: .violet, template: "butterfly"),
        .init(sheet: "D5", slot: 10, title: "Wiggly Worm", emoji: "🪱", tier: .numberTrail, palette: .coral, template: "worm"),
        .init(sheet: "D5", slot: 11, title: "Onion", emoji: "🧅", tier: .firstDots, palette: .gold, template: "onion"),
        .init(sheet: "D5", slot: 12, title: "Lotus Flower", emoji: "🪷", tier: .firstDots, palette: .coral, template: "lotus"),
        .init(sheet: "D5", slot: 13, title: "Sweetcorn", emoji: "🌽", tier: .numberTrail, palette: .gold, template: "corn"),
        .init(sheet: "D5", slot: 14, title: "Pea Pod", emoji: "🫛", tier: .numberTrail, palette: .lime, template: "peas"),
        .init(sheet: "D5", slot: 15, title: "Shrimp", emoji: "🦐", tier: .numberTrail, palette: .coral, template: "shrimp"),

        .init(sheet: "D6", slot: 1, title: "Ant", emoji: "🐜", tier: .numberTrail, palette: .coral, template: "ant"),
        .init(sheet: "D6", slot: 2, title: "Parrot", emoji: "🦜", tier: .numberExplorer, palette: .lime, template: "parrot"),
        .init(sheet: "D6", slot: 3, title: "Flamingo", emoji: "🦩", tier: .numberExplorer, palette: .coral, template: "flamingo"),
        .init(sheet: "D6", slot: 4, title: "Cottage", emoji: "🏠", tier: .numberTrail, palette: .sky, template: "cottage"),
        .init(sheet: "D6", slot: 5, title: "Potted Flower", emoji: "🌼", tier: .firstDots, palette: .coral, template: "potted-flower"),
        .init(sheet: "D6", slot: 6, title: "Hatching Chick", emoji: "🐣", tier: .numberTrail, palette: .gold, template: "hatching-chick"),
        .init(sheet: "D6", slot: 7, title: "Rain Cloud", emoji: "🌧️", tier: .firstDots, palette: .sky, template: "rain-cloud"),
        .init(sheet: "D6", slot: 8, title: "Penguin", emoji: "🐧", tier: .numberTrail, palette: .aqua, template: "penguin"),
        .init(sheet: "D6", slot: 9, title: "Chameleon", emoji: "🦎", tier: .numberExplorer, palette: .lime, template: "chameleon"),
        .init(sheet: "D6", slot: 10, title: "Rabbit", emoji: "🐰", tier: .numberTrail, palette: .aqua, template: "rabbit"),
        .init(sheet: "D6", slot: 11, title: "Mushroom", emoji: "🍄", tier: .firstDots, palette: .coral, template: "mushroom"),
        .init(sheet: "D6", slot: 12, title: "Sandcastle", emoji: "🏰", tier: .numberTrail, palette: .gold, template: "sandcastle"),
        .init(sheet: "D6", slot: 13, title: "Caterpillar", emoji: "🐛", tier: .numberTrail, palette: .lime, template: "caterpillar"),
        .init(sheet: "D6", slot: 14, title: "Ice Cream", emoji: "🍦", tier: .firstDots, palette: .coral, template: "ice-cream"),
        .init(sheet: "D6", slot: 15, title: "Birthday Cake", emoji: "🎂", tier: .numberTrail, palette: .violet, template: "birthday-cake"),

        .init(sheet: "D7", slot: 1, title: "Ladybird", emoji: "🐞", tier: .numberTrail, palette: .coral, template: "ladybird"),
        .init(sheet: "D7", slot: 2, title: "Gorilla", emoji: "🦍", tier: .numberExplorer, palette: .aqua, template: "gorilla"),
        .init(sheet: "D7", slot: 3, title: "Cupcake", emoji: "🧁", tier: .firstDots, palette: .violet, template: "cupcake"),
        .init(sheet: "D7", slot: 4, title: "Ice Lolly", emoji: "🍭", tier: .firstDots, palette: .sky, template: "ice-lolly"),
        .init(sheet: "D7", slot: 5, title: "Strawberry", emoji: "🍓", tier: .firstDots, palette: .coral, template: "strawberry"),
        .init(sheet: "D7", slot: 6, title: "Hot Chocolate", emoji: "☕️", tier: .firstDots, palette: .gold, template: "hot-chocolate"),
        .init(sheet: "D7", slot: 7, title: "Milkshake", emoji: "🥤", tier: .numberTrail, palette: .coral, template: "milkshake"),
        .init(sheet: "D7", slot: 8, title: "Doughnut", emoji: "🍩", tier: .firstDots, palette: .gold, template: "doughnut"),
        .init(sheet: "D7", slot: 9, title: "Zebra", emoji: "🦓", tier: .numberExplorer, palette: .aqua, template: "zebra")
    ]
}
