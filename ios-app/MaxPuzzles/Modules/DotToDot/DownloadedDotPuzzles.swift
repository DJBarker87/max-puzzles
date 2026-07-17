import SwiftUI

extension DotPuzzleCatalog {
    /// Eighty-four distinct pictures visible across d1–d7. d1 and d2 contain the same contact
    /// sheet, so those fifteen designs intentionally appear once rather than as duplicate games.
    static let downloadedReferencePuzzles: [DotPuzzle] =
        DownloadedDotPuzzlePack.build(using: classicPuzzles)
}

private enum DownloadedDotPuzzlePack {
    private struct Spec {
        let sheet: String
        let slot: Int
        let title: String
        let emoji: String
        let tier: DotToDotTier
        let palette: DotPuzzlePalette
        let template: String
    }

    private struct Template {
        let outline: [CGPoint]
        let guides: [[CGPoint]]
        let details: [[CGPoint]]

        init(outline: [CGPoint], guides: [[CGPoint]], details: [[CGPoint]] = []) {
            self.outline = outline
            self.guides = guides
            self.details = details
        }

        init(puzzle: DotPuzzle) {
            outline = puzzle.revealOutline
            guides = puzzle.guidePaths
            details = puzzle.detailPaths
        }
    }

    static func build(using classicPuzzles: [DotPuzzle]) -> [DotPuzzle] {
        let library = Dictionary(uniqueKeysWithValues: classicPuzzles.map { ($0.id, $0) })

        return specs.map { spec in
            let idSlot = spec.slot < 10 ? "0\(spec.slot)" : "\(spec.slot)"
            let sheetID = spec.sheet.lowercased().replacingOccurrences(of: "/", with: "-")
            let puzzleID = "reference-\(sheetID)-\(idSlot)-\(spec.template)"
            let artwork = template(named: spec.template, library: library)
            let extractedTrail = DownloadedDotPuzzleArtwork.trail(
                sheet: spec.sheet,
                slot: spec.slot,
                expectedCount: spec.tier.maxNumeral
            )
            let fallbackTrail = DotPuzzleGeometry.makeNumberTrail(
                artwork.outline,
                count: spec.tier.maxNumeral,
                puzzleID: puzzleID
            )
            let matchingTrail = extractedTrail.count == spec.tier.maxNumeral
                ? extractedTrail
                : fallbackTrail
            let referenceArt = DownloadedDotPuzzleArtwork.referenceArt(
                sheet: spec.sheet,
                slot: spec.slot
            )

            return DotPuzzle(
                id: puzzleID,
                title: spec.title,
                emoji: spec.emoji,
                tier: spec.tier,
                palette: spec.palette,
                outline: matchingTrail,
                trail: matchingTrail,
                guidePaths: referenceArt == nil ? artwork.guides : [],
                detailPaths: referenceArt == nil ? artwork.details : [],
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

    // MARK: - Artwork templates

    private static func template(
        named name: String,
        library: [String: DotPuzzle]
    ) -> Template {
        if let puzzle = library[name] {
            return Template(puzzle: puzzle)
        }

        switch name {
        case "tiger":
            return decorated("cat", library: library, guides: [
                [p(0.30, 0.30), p(0.39, 0.39)], [p(0.50, 0.25), p(0.50, 0.39)],
                [p(0.70, 0.30), p(0.61, 0.39)]
            ])
        case "hamster":
            return decorated("mouse", library: library, guides: [
                oval(0.34, 0.61, 0.08, 0.06), oval(0.66, 0.61, 0.08, 0.06)
            ])
        case "dump-truck":
            return Template(
                outline: [p(0.07, 0.71), p(0.10, 0.42), p(0.52, 0.42), p(0.58, 0.55), p(0.68, 0.55), p(0.72, 0.31), p(0.88, 0.40), p(0.94, 0.70), p(0.82, 0.71), p(0.78, 0.89), p(0.62, 0.89), p(0.58, 0.71), p(0.35, 0.71), p(0.31, 0.89), p(0.15, 0.89)],
                guides: [box(0.16, 0.47, 0.31, 0.18), box(0.72, 0.40, 0.12, 0.14), oval(0.23, 0.79, 0.07, 0.07), oval(0.70, 0.79, 0.07, 0.07)],
                details: [[p(0.16, 0.47), p(0.24, 0.63), p(0.46, 0.63)]]
            )
        case "stingray":
            return Template(
                outline: [p(0.06, 0.47), p(0.25, 0.29), p(0.50, 0.10), p(0.75, 0.29), p(0.94, 0.47), p(0.73, 0.59), p(0.58, 0.66), p(0.57, 0.83), p(0.50, 0.96), p(0.43, 0.82), p(0.42, 0.66), p(0.27, 0.59)],
                guides: [oval(0.39, 0.42, 0.025, 0.025), oval(0.61, 0.42, 0.025, 0.025), [p(0.41, 0.52), p(0.50, 0.57), p(0.59, 0.52)]],
                details: [[p(0.25, 0.47), p(0.38, 0.57)], [p(0.75, 0.47), p(0.62, 0.57)]]
            )
        case "tapir":
            return Template(
                outline: [p(0.06, 0.55), p(0.18, 0.38), p(0.31, 0.24), p(0.57, 0.22), p(0.75, 0.31), p(0.88, 0.40), p(0.95, 0.37), p(0.91, 0.54), p(0.78, 0.59), p(0.76, 0.88), p(0.64, 0.88), p(0.61, 0.61), p(0.40, 0.61), p(0.37, 0.89), p(0.24, 0.89), p(0.22, 0.62)],
                guides: [oval(0.77, 0.40, 0.022, 0.022), [p(0.71, 0.34), p(0.63, 0.43), p(0.69, 0.52)], [p(0.83, 0.48), p(0.92, 0.47)]],
                details: [[p(0.43, 0.59), p(0.43, 0.87)], [p(0.64, 0.59), p(0.64, 0.86)]]
            )
        case "scooter":
            return Template(
                outline: [p(0.08, 0.69), p(0.17, 0.48), p(0.35, 0.44), p(0.43, 0.27), p(0.64, 0.27), p(0.71, 0.42), p(0.88, 0.48), p(0.94, 0.68), p(0.82, 0.70), p(0.78, 0.88), p(0.63, 0.88), p(0.58, 0.70), p(0.36, 0.70), p(0.31, 0.88), p(0.16, 0.88)],
                guides: [oval(0.24, 0.78, 0.075, 0.075), oval(0.70, 0.78, 0.075, 0.075), [p(0.43, 0.34), p(0.63, 0.34)], [p(0.66, 0.27), p(0.72, 0.16), p(0.82, 0.16)]],
                details: [box(0.45, 0.41, 0.16, 0.10)]
            )
        case "pelican":
            return Template(
                outline: [p(0.09, 0.48), p(0.30, 0.40), p(0.39, 0.22), p(0.52, 0.14), p(0.63, 0.23), p(0.60, 0.38), p(0.91, 0.34), p(0.83, 0.51), p(0.70, 0.55), p(0.75, 0.75), p(0.64, 0.88), p(0.48, 0.77), p(0.31, 0.84), p(0.20, 0.68)],
                guides: [oval(0.52, 0.25, 0.022, 0.022), [p(0.59, 0.34), p(0.83, 0.42), p(0.61, 0.46)], [p(0.30, 0.55), p(0.48, 0.48), p(0.58, 0.62), p(0.38, 0.69), p(0.30, 0.55)]],
                details: [[p(0.52, 0.77), p(0.50, 0.93)], [p(0.63, 0.79), p(0.67, 0.94)]]
            )
        case "ostrich":
            return Template(
                outline: [p(0.32, 0.90), p(0.34, 0.61), p(0.20, 0.50), p(0.24, 0.31), p(0.43, 0.24), p(0.57, 0.34), p(0.61, 0.18), p(0.69, 0.07), p(0.82, 0.10), p(0.86, 0.22), p(0.75, 0.28), p(0.69, 0.45), p(0.63, 0.62), p(0.66, 0.90), p(0.55, 0.91), p(0.52, 0.63), p(0.44, 0.61), p(0.43, 0.90)],
                guides: [oval(0.75, 0.17, 0.02, 0.02), [p(0.30, 0.39), p(0.46, 0.34), p(0.54, 0.50), p(0.36, 0.57), p(0.30, 0.39)]],
                details: [[p(0.32, 0.90), p(0.25, 0.94)], [p(0.66, 0.90), p(0.73, 0.94)]]
            )
        case "llama":
            return Template(
                outline: [p(0.14, 0.88), p(0.15, 0.47), p(0.25, 0.34), p(0.60, 0.34), p(0.67, 0.21), p(0.66, 0.08), p(0.75, 0.16), p(0.84, 0.08), p(0.86, 0.25), p(0.80, 0.36), p(0.76, 0.53), p(0.82, 0.88), p(0.69, 0.88), p(0.65, 0.60), p(0.42, 0.60), p(0.39, 0.89), p(0.27, 0.89), p(0.26, 0.61)],
                guides: [oval(0.78, 0.25, 0.02, 0.02), [p(0.23, 0.42), p(0.31, 0.48)], [p(0.40, 0.39), p(0.48, 0.48)], [p(0.56, 0.39), p(0.61, 0.48)]],
                details: [[p(0.70, 0.34), p(0.80, 0.37)]]
            )
        case "walrus":
            return Template(
                outline: [p(0.08, 0.59), p(0.18, 0.35), p(0.36, 0.18), p(0.56, 0.16), p(0.73, 0.28), p(0.86, 0.39), p(0.94, 0.55), p(0.83, 0.69), p(0.72, 0.70), p(0.83, 0.86), p(0.61, 0.80), p(0.49, 0.91), p(0.39, 0.78), p(0.16, 0.79)],
                guides: [oval(0.67, 0.39, 0.024, 0.024), oval(0.78, 0.39, 0.024, 0.024), oval(0.72, 0.49, 0.08, 0.055), [p(0.69, 0.52), p(0.66, 0.67)], [p(0.75, 0.52), p(0.78, 0.67)]],
                details: [[p(0.63, 0.48), p(0.49, 0.44)], [p(0.81, 0.48), p(0.92, 0.44)]]
            )
        case "tropical-island":
            return Template(
                outline: [p(0.08, 0.85), p(0.27, 0.77), p(0.42, 0.72), p(0.47, 0.50), p(0.44, 0.25), p(0.26, 0.14), p(0.46, 0.16), p(0.55, 0.05), p(0.58, 0.22), p(0.77, 0.14), p(0.64, 0.30), p(0.57, 0.50), p(0.62, 0.72), p(0.78, 0.77), p(0.93, 0.85), p(0.72, 0.91), p(0.50, 0.88), p(0.28, 0.91)],
                guides: [[p(0.54, 0.22), p(0.53, 0.70)], [p(0.45, 0.29), p(0.60, 0.29)], [p(0.20, 0.83), p(0.38, 0.82)], [p(0.66, 0.82), p(0.84, 0.83)]],
                details: [[p(0.32, 0.73), p(0.47, 0.74)], [p(0.58, 0.74), p(0.73, 0.73)]]
            )
        case "rooster":
            return decorated("chicken", library: library, guides: [
                [p(0.42, 0.18), p(0.38, 0.08), p(0.48, 0.14), p(0.55, 0.05), p(0.58, 0.17)],
                [p(0.25, 0.55), p(0.11, 0.43), p(0.18, 0.63), p(0.08, 0.72)]
            ])
        case "pineapple":
            return Template(
                outline: [p(0.50, 0.05), p(0.57, 0.21), p(0.71, 0.10), p(0.66, 0.27), p(0.82, 0.24), p(0.70, 0.38), p(0.78, 0.55), p(0.72, 0.78), p(0.58, 0.94), p(0.42, 0.94), p(0.28, 0.78), p(0.22, 0.55), p(0.30, 0.38), p(0.18, 0.24), p(0.34, 0.27), p(0.29, 0.10), p(0.43, 0.21)],
                guides: [[p(0.30, 0.45), p(0.66, 0.83)], [p(0.45, 0.34), p(0.73, 0.65)], [p(0.70, 0.45), p(0.34, 0.83)], [p(0.55, 0.34), p(0.27, 0.65)]],
                details: [oval(0.50, 0.61, 0.23, 0.30)]
            )
        case "broccoli":
            return Template(
                outline: [p(0.25, 0.45), p(0.12, 0.34), p(0.17, 0.19), p(0.32, 0.18), p(0.39, 0.08), p(0.52, 0.13), p(0.62, 0.07), p(0.73, 0.18), p(0.87, 0.22), p(0.88, 0.39), p(0.75, 0.48), p(0.65, 0.49), p(0.68, 0.89), p(0.55, 0.94), p(0.45, 0.94), p(0.32, 0.89), p(0.35, 0.49)],
                guides: [[p(0.35, 0.45), p(0.50, 0.62), p(0.65, 0.45)], [p(0.50, 0.42), p(0.50, 0.90)]],
                details: [[p(0.37, 0.76), p(0.63, 0.76)]]
            )
        case "anteater":
            return Template(
                outline: [p(0.04, 0.56), p(0.20, 0.38), p(0.36, 0.23), p(0.58, 0.24), p(0.72, 0.34), p(0.89, 0.39), p(0.96, 0.47), p(0.85, 0.54), p(0.73, 0.55), p(0.69, 0.87), p(0.57, 0.87), p(0.54, 0.60), p(0.35, 0.60), p(0.31, 0.88), p(0.19, 0.88), p(0.18, 0.62)],
                guides: [oval(0.76, 0.40, 0.021, 0.021), [p(0.67, 0.34), p(0.62, 0.46), p(0.71, 0.54)], [p(0.10, 0.52), p(0.21, 0.59)]],
                details: [[p(0.36, 0.59), p(0.36, 0.86)], [p(0.57, 0.59), p(0.57, 0.86)]]
            )
        case "cherries":
            return Template(
                outline: [p(0.50, 0.08), p(0.61, 0.18), p(0.69, 0.38), p(0.83, 0.42), p(0.92, 0.59), p(0.87, 0.79), p(0.71, 0.91), p(0.55, 0.84), p(0.46, 0.69), p(0.37, 0.86), p(0.19, 0.89), p(0.08, 0.73), p(0.10, 0.53), p(0.25, 0.40), p(0.39, 0.40)],
                guides: [oval(0.28, 0.65, 0.16, 0.18), oval(0.70, 0.66, 0.16, 0.18), [p(0.28, 0.47), p(0.50, 0.10)], [p(0.70, 0.48), p(0.50, 0.10)]],
                details: [[p(0.50, 0.12), p(0.66, 0.08), p(0.61, 0.19)]]
            )
        case "red-panda":
            return decorated("fox", library: library, guides: [
                oval(0.38, 0.44, 0.08, 0.055), oval(0.62, 0.44, 0.08, 0.055),
                [p(0.24, 0.70), p(0.34, 0.74)], [p(0.66, 0.74), p(0.76, 0.70)]
            ])
        case "hand":
            return Template(
                outline: [p(0.21, 0.92), p(0.16, 0.71), p(0.08, 0.51), p(0.14, 0.43), p(0.27, 0.56), p(0.25, 0.23), p(0.32, 0.17), p(0.39, 0.23), p(0.40, 0.09), p(0.48, 0.06), p(0.54, 0.13), p(0.57, 0.07), p(0.65, 0.10), p(0.67, 0.19), p(0.73, 0.16), p(0.80, 0.21), p(0.78, 0.48), p(0.72, 0.68), p(0.62, 0.91), p(0.42, 0.96)],
                guides: [[p(0.31, 0.60), p(0.45, 0.54), p(0.61, 0.57)], [p(0.37, 0.72), p(0.57, 0.71)]],
                details: [[p(0.31, 0.26), p(0.34, 0.49)], [p(0.48, 0.13), p(0.48, 0.46)], [p(0.62, 0.16), p(0.60, 0.47)]]
            )
        case "raccoon":
            return decorated("fox", library: library, guides: [
                [p(0.25, 0.42), p(0.39, 0.35), p(0.48, 0.45)],
                [p(0.52, 0.45), p(0.61, 0.35), p(0.75, 0.42)],
                [p(0.29, 0.74), p(0.39, 0.78)], [p(0.61, 0.78), p(0.71, 0.74)]
            ])
        case "grasshopper":
            return Template(
                outline: [p(0.08, 0.61), p(0.22, 0.45), p(0.36, 0.42), p(0.45, 0.26), p(0.57, 0.22), p(0.66, 0.35), p(0.84, 0.32), p(0.94, 0.43), p(0.84, 0.54), p(0.70, 0.55), p(0.84, 0.78), p(0.73, 0.83), p(0.55, 0.62), p(0.42, 0.66), p(0.26, 0.86), p(0.15, 0.80), p(0.27, 0.62)],
                guides: [oval(0.84, 0.42, 0.021, 0.021), [p(0.64, 0.37), p(0.50, 0.48), p(0.65, 0.56)], [p(0.35, 0.47), p(0.22, 0.36)], [p(0.76, 0.34), p(0.83, 0.20)]],
                details: [[p(0.42, 0.59), p(0.30, 0.73)], [p(0.58, 0.57), p(0.70, 0.75)]]
            )
        case "worm":
            return Template(
                outline: [p(0.08, 0.62), p(0.16, 0.43), p(0.31, 0.38), p(0.42, 0.47), p(0.54, 0.36), p(0.68, 0.32), p(0.84, 0.40), p(0.93, 0.55), p(0.86, 0.70), p(0.71, 0.72), p(0.57, 0.64), p(0.46, 0.75), p(0.30, 0.80), p(0.15, 0.76)],
                guides: [oval(0.82, 0.50, 0.022, 0.022), [p(0.79, 0.60), p(0.84, 0.63), p(0.89, 0.59)], [p(0.26, 0.43), p(0.30, 0.75)], [p(0.47, 0.45), p(0.51, 0.68)], [p(0.67, 0.36), p(0.70, 0.69)]],
                details: [[p(0.78, 0.41), p(0.75, 0.29)], [p(0.86, 0.42), p(0.91, 0.31)]]
            )
        case "onion":
            return Template(
                outline: [p(0.50, 0.05), p(0.57, 0.22), p(0.70, 0.10), p(0.66, 0.29), p(0.82, 0.43), p(0.86, 0.65), p(0.76, 0.84), p(0.58, 0.94), p(0.50, 0.87), p(0.42, 0.94), p(0.24, 0.84), p(0.14, 0.65), p(0.18, 0.43), p(0.34, 0.29), p(0.30, 0.10), p(0.43, 0.22)],
                guides: [[p(0.50, 0.28), p(0.39, 0.46), p(0.38, 0.72), p(0.50, 0.87)], [p(0.50, 0.28), p(0.61, 0.46), p(0.62, 0.72), p(0.50, 0.87)]],
                details: [[p(0.31, 0.55), p(0.69, 0.55)]]
            )
        case "lotus":
            return Template(
                outline: [p(0.07, 0.66), p(0.20, 0.48), p(0.31, 0.47), p(0.28, 0.25), p(0.44, 0.38), p(0.50, 0.09), p(0.56, 0.38), p(0.72, 0.25), p(0.69, 0.47), p(0.80, 0.48), p(0.93, 0.66), p(0.72, 0.68), p(0.61, 0.84), p(0.50, 0.73), p(0.39, 0.84), p(0.28, 0.68)],
                guides: [[p(0.20, 0.55), p(0.40, 0.68), p(0.50, 0.47), p(0.60, 0.68), p(0.80, 0.55)], [p(0.12, 0.74), p(0.88, 0.74)]],
                details: [oval(0.50, 0.70, 0.35, 0.07)]
            )
        case "corn":
            return Template(
                outline: [p(0.50, 0.05), p(0.66, 0.13), p(0.72, 0.34), p(0.88, 0.27), p(0.78, 0.61), p(0.67, 0.88), p(0.51, 0.95), p(0.35, 0.88), p(0.22, 0.61), p(0.12, 0.27), p(0.28, 0.34), p(0.34, 0.13)],
                guides: [oval(0.50, 0.48, 0.19, 0.34), [p(0.31, 0.32), p(0.69, 0.65)], [p(0.69, 0.32), p(0.31, 0.65)], [p(0.31, 0.48), p(0.69, 0.48)]],
                details: [[p(0.27, 0.37), p(0.36, 0.83)], [p(0.73, 0.37), p(0.64, 0.83)]]
            )
        case "peas":
            return Template(
                outline: [p(0.06, 0.52), p(0.20, 0.33), p(0.42, 0.22), p(0.67, 0.25), p(0.88, 0.39), p(0.96, 0.53), p(0.84, 0.69), p(0.62, 0.78), p(0.37, 0.76), p(0.16, 0.66)],
                guides: [oval(0.28, 0.52, 0.09, 0.11), oval(0.47, 0.49, 0.09, 0.11), oval(0.66, 0.50, 0.09, 0.11), [p(0.12, 0.46), p(0.31, 0.35), p(0.57, 0.32), p(0.83, 0.43)]],
                details: [[p(0.17, 0.62), p(0.38, 0.69), p(0.64, 0.68), p(0.84, 0.58)]]
            )
        case "shrimp":
            return Template(
                outline: [p(0.08, 0.49), p(0.20, 0.31), p(0.40, 0.20), p(0.61, 0.25), p(0.78, 0.38), p(0.92, 0.34), p(0.86, 0.52), p(0.94, 0.66), p(0.77, 0.65), p(0.63, 0.77), p(0.45, 0.82), p(0.27, 0.74), p(0.15, 0.63)],
                guides: [oval(0.74, 0.39, 0.022, 0.022), [p(0.31, 0.29), p(0.38, 0.73)], [p(0.45, 0.24), p(0.50, 0.74)], [p(0.59, 0.27), p(0.63, 0.68)]],
                details: [[p(0.83, 0.37), p(0.90, 0.22)], [p(0.79, 0.40), p(0.82, 0.23)]]
            )
        case "ant":
            return Template(
                outline: [p(0.08, 0.56), p(0.20, 0.38), p(0.35, 0.37), p(0.43, 0.22), p(0.57, 0.22), p(0.65, 0.37), p(0.80, 0.38), p(0.92, 0.56), p(0.80, 0.71), p(0.66, 0.68), p(0.58, 0.84), p(0.42, 0.84), p(0.34, 0.68), p(0.20, 0.71)],
                guides: [oval(0.28, 0.54, 0.12, 0.13), oval(0.50, 0.50, 0.11, 0.14), oval(0.73, 0.54, 0.12, 0.13), [p(0.77, 0.42), p(0.84, 0.25)], [p(0.72, 0.41), p(0.71, 0.23)]],
                details: [[p(0.38, 0.55), p(0.23, 0.27)], [p(0.41, 0.62), p(0.28, 0.85)], [p(0.60, 0.55), p(0.75, 0.27)], [p(0.59, 0.62), p(0.72, 0.85)]]
            )
        case "parrot":
            return Template(
                outline: [p(0.31, 0.91), p(0.27, 0.67), p(0.17, 0.53), p(0.20, 0.33), p(0.35, 0.21), p(0.48, 0.08), p(0.64, 0.11), p(0.73, 0.25), p(0.91, 0.31), p(0.78, 0.43), p(0.75, 0.61), p(0.62, 0.74), p(0.53, 0.91), p(0.43, 0.72)],
                guides: [oval(0.58, 0.22, 0.024, 0.024), [p(0.70, 0.28), p(0.88, 0.34), p(0.73, 0.39)], [p(0.31, 0.46), p(0.51, 0.35), p(0.65, 0.53), p(0.46, 0.67), p(0.31, 0.46)]],
                details: [[p(0.38, 0.69), p(0.38, 0.93)], [p(0.49, 0.71), p(0.47, 0.94)]]
            )
        case "flamingo":
            return Template(
                outline: [p(0.30, 0.92), p(0.31, 0.61), p(0.18, 0.50), p(0.22, 0.31), p(0.42, 0.22), p(0.55, 0.34), p(0.62, 0.20), p(0.68, 0.06), p(0.81, 0.10), p(0.90, 0.19), p(0.80, 0.27), p(0.69, 0.31), p(0.66, 0.48), p(0.62, 0.63), p(0.68, 0.92), p(0.57, 0.92), p(0.52, 0.63), p(0.43, 0.61), p(0.42, 0.92)],
                guides: [oval(0.75, 0.17, 0.021, 0.021), [p(0.27, 0.37), p(0.43, 0.32), p(0.55, 0.49), p(0.36, 0.57), p(0.27, 0.37)]],
                details: [[p(0.30, 0.92), p(0.23, 0.95)], [p(0.68, 0.92), p(0.75, 0.95)]]
            )
        case "cottage":
            return decorated("house", library: library, guides: [
                box(0.42, 0.63, 0.16, 0.27), [p(0.68, 0.27), p(0.68, 0.12), p(0.78, 0.12), p(0.78, 0.36)]
            ])
        case "potted-flower":
            return Template(
                outline: [p(0.31, 0.92), p(0.27, 0.66), p(0.40, 0.65), p(0.39, 0.50), p(0.22, 0.42), p(0.34, 0.31), p(0.31, 0.15), p(0.48, 0.23), p(0.50, 0.06), p(0.52, 0.23), p(0.69, 0.15), p(0.66, 0.31), p(0.78, 0.42), p(0.61, 0.50), p(0.60, 0.65), p(0.73, 0.66), p(0.69, 0.92)],
                guides: [oval(0.50, 0.36, 0.10, 0.10), [p(0.50, 0.46), p(0.50, 0.67)], [p(0.28, 0.68), p(0.72, 0.68)], [p(0.36, 0.69), p(0.40, 0.89)], [p(0.64, 0.69), p(0.60, 0.89)]],
                details: [[p(0.50, 0.56), p(0.38, 0.51)], [p(0.50, 0.60), p(0.63, 0.54)]]
            )
        case "hatching-chick":
            return Template(
                outline: [p(0.50, 0.06), p(0.64, 0.14), p(0.72, 0.30), p(0.84, 0.35), p(0.76, 0.49), p(0.86, 0.61), p(0.72, 0.68), p(0.66, 0.88), p(0.50, 0.96), p(0.34, 0.88), p(0.28, 0.68), p(0.14, 0.61), p(0.24, 0.49), p(0.16, 0.35), p(0.28, 0.30), p(0.36, 0.14)],
                guides: [oval(0.40, 0.34, 0.022, 0.022), oval(0.60, 0.34, 0.022, 0.022), [p(0.46, 0.43), p(0.50, 0.48), p(0.54, 0.43)], [p(0.18, 0.62), p(0.32, 0.56), p(0.43, 0.68), p(0.55, 0.57), p(0.70, 0.67), p(0.82, 0.61)]],
                details: [[p(0.30, 0.74), p(0.70, 0.74)]]
            )
        case "rain-cloud":
            return decorated("cloud", library: library, guides: [
                [p(0.30, 0.80), p(0.26, 0.92)], [p(0.50, 0.80), p(0.46, 0.94)], [p(0.70, 0.80), p(0.66, 0.92)]
            ])
        case "chameleon":
            return decorated("crocodile", library: library, guides: [
                spiral(0.23, 0.52, 0.14), oval(0.77, 0.42, 0.055, 0.055),
                [p(0.46, 0.42), p(0.57, 0.51), p(0.46, 0.60)]
            ])
        case "mushroom":
            return Template(
                outline: [p(0.08, 0.49), p(0.17, 0.27), p(0.34, 0.12), p(0.50, 0.07), p(0.66, 0.12), p(0.83, 0.27), p(0.92, 0.49), p(0.68, 0.46), p(0.66, 0.87), p(0.56, 0.95), p(0.44, 0.95), p(0.34, 0.87), p(0.32, 0.46)],
                guides: [[p(0.12, 0.48), p(0.88, 0.48)], oval(0.37, 0.30, 0.055, 0.05), oval(0.60, 0.25, 0.04, 0.04), [p(0.36, 0.77), p(0.64, 0.77)]],
                details: [[p(0.45, 0.58), p(0.43, 0.87)], [p(0.55, 0.58), p(0.57, 0.87)]]
            )
        case "sandcastle":
            return decorated("castle", library: library, guides: [
                [p(0.12, 0.84), p(0.88, 0.84)], oval(0.25, 0.72, 0.035, 0.025), oval(0.75, 0.73, 0.035, 0.025)
            ])
        case "caterpillar":
            return Template(
                outline: [p(0.07, 0.56), p(0.16, 0.38), p(0.31, 0.34), p(0.43, 0.23), p(0.57, 0.26), p(0.69, 0.20), p(0.84, 0.30), p(0.94, 0.46), p(0.87, 0.63), p(0.73, 0.66), p(0.60, 0.75), p(0.46, 0.70), p(0.32, 0.80), p(0.18, 0.73)],
                guides: [oval(0.18, 0.55, 0.10, 0.13), oval(0.37, 0.51, 0.10, 0.13), oval(0.56, 0.48, 0.10, 0.13), oval(0.75, 0.46, 0.10, 0.13), oval(0.82, 0.40, 0.02, 0.02)],
                details: [[p(0.77, 0.32), p(0.73, 0.18)], [p(0.84, 0.32), p(0.89, 0.19)], [p(0.25, 0.67), p(0.22, 0.87)], [p(0.48, 0.65), p(0.46, 0.87)], [p(0.68, 0.61), p(0.70, 0.81)]]
            )
        case "birthday-cake":
            return Template(
                outline: [p(0.14, 0.91), p(0.14, 0.48), p(0.24, 0.42), p(0.24, 0.27), p(0.31, 0.21), p(0.45, 0.21), p(0.45, 0.10), p(0.50, 0.04), p(0.55, 0.10), p(0.55, 0.21), p(0.69, 0.21), p(0.76, 0.27), p(0.76, 0.42), p(0.86, 0.48), p(0.86, 0.91)],
                guides: [[p(0.15, 0.49), p(0.27, 0.44), p(0.39, 0.49), p(0.51, 0.44), p(0.63, 0.49), p(0.75, 0.44), p(0.85, 0.49)], [p(0.14, 0.66), p(0.86, 0.66)], [p(0.14, 0.80), p(0.86, 0.80)]],
                details: [oval(0.36, 0.58, 0.03, 0.03), oval(0.64, 0.58, 0.03, 0.03), [p(0.43, 0.73), p(0.50, 0.77), p(0.57, 0.73)]]
            )
        case "gorilla":
            return decorated("monkey", library: library, guides: [
                oval(0.50, 0.68, 0.25, 0.17), [p(0.24, 0.58), p(0.12, 0.82)], [p(0.76, 0.58), p(0.88, 0.82)],
                [p(0.39, 0.70), p(0.50, 0.76), p(0.61, 0.70)]
            ])
        case "ice-lolly":
            return Template(
                outline: [p(0.36, 0.91), p(0.36, 0.72), p(0.25, 0.61), p(0.24, 0.23), p(0.34, 0.09), p(0.50, 0.05), p(0.66, 0.09), p(0.76, 0.23), p(0.75, 0.61), p(0.64, 0.72), p(0.64, 0.91), p(0.56, 0.96), p(0.44, 0.96)],
                guides: [[p(0.25, 0.31), p(0.75, 0.31)], [p(0.25, 0.50), p(0.75, 0.50)], [p(0.39, 0.20), p(0.42, 0.20)], [p(0.58, 0.20), p(0.61, 0.20)], [p(0.43, 0.60), p(0.50, 0.64), p(0.57, 0.60)]],
                details: [[p(0.45, 0.73), p(0.45, 0.92)], [p(0.55, 0.73), p(0.55, 0.92)]]
            )
        case "hot-chocolate":
            return Template(
                outline: [p(0.14, 0.35), p(0.21, 0.21), p(0.70, 0.21), p(0.78, 0.32), p(0.91, 0.34), p(0.95, 0.51), p(0.88, 0.67), p(0.76, 0.68), p(0.68, 0.84), p(0.27, 0.84), p(0.18, 0.67)],
                guides: [oval(0.47, 0.28, 0.28, 0.07), [p(0.79, 0.38), p(0.88, 0.39), p(0.89, 0.57), p(0.78, 0.61)], [p(0.35, 0.13), p(0.31, 0.05)], [p(0.50, 0.13), p(0.54, 0.04)], [p(0.64, 0.13), p(0.61, 0.05)]],
                details: [oval(0.47, 0.45, 0.025, 0.025), [p(0.39, 0.58), p(0.47, 0.63), p(0.55, 0.58)]]
            )
        case "milkshake":
            return Template(
                outline: [p(0.25, 0.91), p(0.20, 0.42), p(0.28, 0.29), p(0.35, 0.22), p(0.43, 0.14), p(0.57, 0.14), p(0.65, 0.22), p(0.72, 0.29), p(0.80, 0.42), p(0.75, 0.91)],
                guides: [[p(0.21, 0.44), p(0.79, 0.44)], [p(0.28, 0.58), p(0.72, 0.58)], [p(0.60, 0.18), p(0.72, 0.04)], oval(0.50, 0.28, 0.20, 0.10)],
                details: [oval(0.42, 0.69, 0.024, 0.024), oval(0.58, 0.69, 0.024, 0.024), [p(0.42, 0.78), p(0.50, 0.83), p(0.58, 0.78)]]
            )
        case "doughnut":
            return Template(
                outline: (0..<20).map { index in
                    let angle = CGFloat(index) / 20 * CGFloat.pi * 2
                    return p(0.50 + cos(angle) * 0.42, 0.50 + sin(angle) * 0.40)
                },
                guides: [oval(0.50, 0.50, 0.15, 0.14), [p(0.18, 0.39), p(0.31, 0.44)], [p(0.66, 0.28), p(0.76, 0.36)], [p(0.66, 0.68), p(0.76, 0.63)]],
                details: [[p(0.26, 0.64), p(0.36, 0.59)], [p(0.46, 0.20), p(0.50, 0.30)], [p(0.54, 0.75), p(0.59, 0.66)]]
            )
        default:
            preconditionFailure("Missing downloaded dot-to-dot template: \(name)")
        }
    }

    private static func decorated(
        _ baseID: String,
        library: [String: DotPuzzle],
        guides: [[CGPoint]],
        details: [[CGPoint]] = []
    ) -> Template {
        guard let puzzle = library[baseID] else {
            preconditionFailure("Missing classic dot-to-dot template: \(baseID)")
        }
        return Template(
            outline: puzzle.revealOutline,
            guides: puzzle.guidePaths + guides,
            details: puzzle.detailPaths + details
        )
    }

    // MARK: - Deterministic sheet variations

    private static func variationIndex(sheet: String, slot: Int) -> Int {
        // The frog's deliberately symmetrical numeral choices are part of its challenge; retain
        // uniform scaling so an anisotropic sheet variation cannot erase that spatial ambiguity.
        if sheet == "D4", slot == 10 { return 0 }
        let sheetSeed = sheet.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (sheetSeed + slot) % 8
    }

    /// A cyclic outline can begin at any authored point. Prefer a start that makes at least one
    /// later numeral spatially plausible, so the activity tests numeral order rather than merely
    /// following the closest dot. Geometry is unchanged; only where numeral 1 begins can rotate.
    private static func touchFriendlyTrail(_ outline: [CGPoint], count: Int) -> [CGPoint]? {
        guard outline.count == count else { return nil }
        return DotPuzzleGeometry.withMeaningfulNumeralStart(outline)
    }

    private static func transform(_ points: [CGPoint], variation: Int) -> [CGPoint] {
        let settings: (scaleX: CGFloat, scaleY: CGFloat, offsetX: CGFloat, offsetY: CGFloat, mirrors: Bool) = switch variation {
        case 1: (0.90, 0.92, -0.02, 0.01, true)
        case 2: (0.88, 0.94, 0.03, -0.01, false)
        case 3: (0.94, 0.86, -0.01, 0.03, false)
        case 4: (0.87, 0.91, -0.03, 0.00, true)
        case 5: (0.91, 0.88, 0.02, 0.03, false)
        case 6: (0.89, 0.93, 0.01, -0.02, true)
        case 7: (0.93, 0.89, -0.02, 0.02, false)
        default: (0.92, 0.92, 0.00, 0.00, false)
        }

        return points.map { point in
            let sourceX = settings.mirrors ? 1 - point.x : point.x
            let x = 0.50 + (sourceX - 0.50) * settings.scaleX + settings.offsetX
            let y = 0.50 + (point.y - 0.50) * settings.scaleY + settings.offsetY
            return p(min(max(x, 0.035), 0.965), min(max(y, 0.035), 0.965))
        }
    }

    // MARK: - Small vector helpers

    private static func oval(
        _ centerX: CGFloat,
        _ centerY: CGFloat,
        _ radiusX: CGFloat,
        _ radiusY: CGFloat,
        steps: Int = 12
    ) -> [CGPoint] {
        (0...steps).map { index in
            let angle = -CGFloat.pi / 2 + CGFloat(index) / CGFloat(steps) * CGFloat.pi * 2
            return p(centerX + cos(angle) * radiusX, centerY + sin(angle) * radiusY)
        }
    }

    private static func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> [CGPoint] {
        [p(x, y), p(x + width, y), p(x + width, y + height), p(x, y + height), p(x, y)]
    }

    private static func spiral(_ centerX: CGFloat, _ centerY: CGFloat, _ radius: CGFloat) -> [CGPoint] {
        (0...22).map { index in
            let fraction = CGFloat(index) / 22
            let angle = fraction * CGFloat.pi * 4.5
            let currentRadius = radius * (1 - fraction * 0.82)
            return p(centerX + cos(angle) * currentRadius, centerY + sin(angle) * currentRadius)
        }
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}
