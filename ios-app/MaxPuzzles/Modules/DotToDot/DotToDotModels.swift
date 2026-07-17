import SwiftUI

enum DotInteractionMode: String, CaseIterable, Identifiable {
    case tap
    case trace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap: return "Tap dots"
        case .trace: return "Trace lines"
        }
    }

    var shortInstruction: String {
        switch self {
        case .tap: return "Press the next numeral"
        case .trace: return "Draw from the last dot to the next"
        }
    }

    var icon: String {
        switch self {
        case .tap: return "hand.tap.fill"
        case .trace: return "pencil.and.outline"
        }
    }
}

enum DotToDotTier: String, CaseIterable, Identifiable {
    case firstDots
    case numberTrail
    case numberExplorer
    case bigNumberAdventure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDots: return "First Dots"
        case .numberTrail: return "Number Trail"
        case .numberExplorer: return "Number Explorer"
        case .bigNumberAdventure: return "Big Number Adventure"
        }
    }

    var subtitle: String {
        switch self {
        case .firstDots: return "A gentle start"
        case .numberTrail: return "Growing confidence"
        case .numberExplorer: return "Numerals to 20"
        case .bigNumberAdventure: return "A special challenge"
        }
    }

    var maxNumeral: Int {
        switch self {
        case .firstDots: return 10
        case .numberTrail: return 15
        case .numberExplorer: return 20
        case .bigNumberAdventure: return 25
        }
    }

    var automaticHintDelay: TimeInterval {
        switch self {
        case .firstDots: return 3.5
        case .numberTrail: return 5
        case .numberExplorer: return 7
        case .bigNumberAdventure: return 9
        }
    }

    var rangeLabel: String { "1–\(maxNumeral)" }

    var color: Color {
        switch self {
        case .firstDots: return Color(hex: "5eead4")
        case .numberTrail: return Color(hex: "fbbf24")
        case .numberExplorer: return Color(hex: "c084fc")
        case .bigNumberAdventure: return Color(hex: "fb7185")
        }
    }

    var icon: String {
        switch self {
        case .firstDots: return "1.circle.fill"
        case .numberTrail: return "circle.grid.2x2.fill"
        case .numberExplorer: return "circle.grid.3x3.fill"
        case .bigNumberAdventure: return "sparkles"
        }
    }
}

enum DotPuzzlePalette: CaseIterable {
    case aqua
    case gold
    case coral
    case violet
    case lime
    case sky

    var primary: Color {
        switch self {
        case .aqua: return Color(hex: "2dd4bf")
        case .gold: return Color(hex: "fbbf24")
        case .coral: return Color(hex: "fb7185")
        case .violet: return Color(hex: "c084fc")
        case .lime: return Color(hex: "a3e635")
        case .sky: return Color(hex: "38bdf8")
        }
    }

    var secondary: Color {
        switch self {
        case .aqua: return Color(hex: "0f766e")
        case .gold: return Color(hex: "d97706")
        case .coral: return Color(hex: "be123c")
        case .violet: return Color(hex: "7e22ce")
        case .lime: return Color(hex: "4d7c0f")
        case .sky: return Color(hex: "0369a1")
        }
    }
}

/// A square tile inside one of the downloaded-art atlases. Keeping the original worksheet
/// drawing separate from the gameplay geometry lets the numbered trail stay touch-friendly while
/// selection cards, the board and the colouring stage all show the recognisable source artwork.
struct DotPuzzleReferenceArt {
    let assetName: String
    let column: Int
    let row: Int
    let columns: Int
    let rows: Int
}

struct DotPuzzle: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let tier: DotToDotTier
    let palette: DotPuzzlePalette
    let points: [CGPoint]
    let revealOutline: [CGPoint]
    /// Lines already present on a traditional worksheet: faces, windows, cone hatching and other
    /// visual anchors. They make the subject engaging without giving away the numbered trail.
    let guidePaths: [[CGPoint]]
    /// Extra finishing strokes that appear once the trail is complete and remain while colouring.
    let detailPaths: [[CGPoint]]
    /// Identifies pictures rebuilt from the parent's d1–d7 reference sheets. The source label is
    /// kept with the puzzle so the pack can be audited without exposing file-system paths in UI.
    let sourceSheet: String?
    let referenceArt: DotPuzzleReferenceArt?

    var usesAngularArtwork: Bool {
        DotPuzzleGeometry.angularArtworkIDs.contains(id)
    }

    init(
        id: String,
        title: String,
        emoji: String,
        tier: DotToDotTier,
        palette: DotPuzzlePalette,
        outline: [CGPoint],
        trail: [CGPoint]? = nil,
        guidePaths: [[CGPoint]] = [],
        detailPaths: [[CGPoint]] = [],
        sourceSheet: String? = nil,
        referenceArt: DotPuzzleReferenceArt? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.tier = tier
        self.palette = palette
        self.sourceSheet = sourceSheet
        self.referenceArt = referenceArt
        self.guidePaths = DotPuzzleArtwork.preDrawnDetails(for: id) + guidePaths
        self.detailPaths = DotPuzzleArtwork.finishingDetails(for: id) + detailPaths
        let numberedTrail: [CGPoint]
        if let trail, trail.count == tier.maxNumeral {
            numberedTrail = trail
        } else {
            numberedTrail = DotPuzzleGeometry.makeNumberTrail(
                outline,
                count: tier.maxNumeral,
                puzzleID: id
            )
        }
        self.points = DotPuzzleGeometry.withMeaningfulNumeralStart(numberedTrail)
        // The revealed exterior must be exactly what the child can make by joining the numbered
        // dots. Keeping a second authored perimeter here can introduce impossible, unnumbered
        // corners between two numerals (particularly on ships and vehicles).
        self.revealOutline = self.points
    }
}

enum DotPuzzleCatalog {
    private static let originalPuzzles: [DotPuzzle] = [
        puzzle("rocket", "Rocket", "🚀", .firstDots, .coral, [
            p(0.50, 0.05), p(0.66, 0.27), p(0.66, 0.58), p(0.84, 0.82),
            p(0.61, 0.76), p(0.50, 0.95), p(0.39, 0.76), p(0.16, 0.82),
            p(0.34, 0.58), p(0.34, 0.27)
        ]),
        puzzle("star", "Star", "⭐️", .firstDots, .gold, [
            p(0.50, 0.06), p(0.61, 0.36), p(0.93, 0.36), p(0.67, 0.55),
            p(0.78, 0.88), p(0.50, 0.68), p(0.22, 0.88), p(0.33, 0.55),
            p(0.07, 0.36), p(0.39, 0.36)
        ]),
        puzzle("fish", "Fish", "🐠", .firstDots, .aqua, [
            p(0.08, 0.51), p(0.27, 0.30), p(0.55, 0.22), p(0.76, 0.34),
            p(0.93, 0.20), p(0.86, 0.50), p(0.93, 0.80), p(0.76, 0.66),
            p(0.55, 0.78), p(0.27, 0.70)
        ]),
        puzzle("house", "House", "🏠", .firstDots, .sky, [
            p(0.10, 0.44), p(0.50, 0.08), p(0.90, 0.44), p(0.80, 0.44),
            p(0.80, 0.90), p(0.60, 0.90), p(0.60, 0.63), p(0.40, 0.63),
            p(0.40, 0.90), p(0.20, 0.90), p(0.20, 0.44)
        ]),
        puzzle("sailboat", "Sailboat", "⛵️", .firstDots, .sky, [
            p(0.10, 0.70), p(0.47, 0.70), p(0.47, 0.16), p(0.51, 0.16),
            p(0.82, 0.63), p(0.53, 0.63), p(0.53, 0.70), p(0.90, 0.70),
            p(0.77, 0.91), p(0.24, 0.91)
        ]),
        puzzle("flower", "Flower", "🌷", .firstDots, .lime, [
            p(0.43, 0.94), p(0.43, 0.66), p(0.22, 0.76), p(0.34, 0.58),
            p(0.39, 0.50), p(0.22, 0.28), p(0.42, 0.36), p(0.50, 0.10),
            p(0.58, 0.36), p(0.78, 0.28), p(0.61, 0.50), p(0.66, 0.58),
            p(0.78, 0.76), p(0.57, 0.66), p(0.57, 0.94)
        ]),
        puzzle("kite", "Kite", "🪁", .firstDots, .violet, [
            p(0.50, 0.06), p(0.84, 0.38), p(0.50, 0.70), p(0.16, 0.38)
        ]),
        puzzle("heart", "Heart", "💖", .firstDots, .coral, [
            p(0.50, 0.91), p(0.15, 0.58), p(0.08, 0.35), p(0.15, 0.16),
            p(0.32, 0.09), p(0.50, 0.28), p(0.68, 0.09), p(0.85, 0.16),
            p(0.92, 0.35), p(0.85, 0.58)
        ]),
        puzzle("moon", "Moon", "🌙", .firstDots, .gold, [
            p(0.68, 0.08), p(0.43, 0.12), p(0.24, 0.28), p(0.15, 0.50),
            p(0.24, 0.72), p(0.43, 0.88), p(0.68, 0.92), p(0.52, 0.77),
            p(0.45, 0.60), p(0.45, 0.40), p(0.52, 0.23)
        ]),
        puzzle("ice-cream", "Ice Cream Cone", "🍦", .firstDots, .coral, [
            p(0.50, 0.95), p(0.27, 0.43), p(0.16, 0.34), p(0.18, 0.18),
            p(0.34, 0.08), p(0.50, 0.14), p(0.66, 0.08), p(0.82, 0.18),
            p(0.84, 0.34), p(0.73, 0.43)
        ]),

        puzzle("cat", "Cat", "🐱", .numberTrail, .gold, [
            p(0.20, 0.31), p(0.21, 0.11), p(0.38, 0.24), p(0.50, 0.20),
            p(0.62, 0.24), p(0.79, 0.11), p(0.80, 0.39), p(0.73, 0.54),
            p(0.68, 0.65), p(0.80, 0.87), p(0.60, 0.78), p(0.50, 0.94),
            p(0.40, 0.78), p(0.20, 0.87), p(0.32, 0.65), p(0.27, 0.54)
        ]),
        puzzle("dog", "Puppy", "🐶", .numberTrail, .coral, [
            p(0.25, 0.25), p(0.10, 0.16), p(0.14, 0.48), p(0.25, 0.55),
            p(0.31, 0.72), p(0.22, 0.91), p(0.43, 0.82), p(0.50, 0.94),
            p(0.57, 0.82), p(0.78, 0.91), p(0.69, 0.72), p(0.75, 0.55),
            p(0.86, 0.48), p(0.90, 0.16), p(0.75, 0.25), p(0.50, 0.18)
        ]),
        puzzle("butterfly", "Butterfly", "🦋", .numberTrail, .violet, [
            p(0.48, 0.18), p(0.27, 0.08), p(0.09, 0.25), p(0.18, 0.48),
            p(0.08, 0.72), p(0.29, 0.89), p(0.48, 0.67), p(0.50, 0.91),
            p(0.52, 0.67), p(0.71, 0.89), p(0.92, 0.72), p(0.82, 0.48),
            p(0.91, 0.25), p(0.73, 0.08), p(0.52, 0.18)
        ]),
        puzzle("turtle", "Turtle", "🐢", .numberTrail, .lime, [
            p(0.16, 0.41), p(0.06, 0.29), p(0.10, 0.51), p(0.20, 0.57),
            p(0.18, 0.78), p(0.35, 0.68), p(0.50, 0.78), p(0.65, 0.68),
            p(0.82, 0.78), p(0.80, 0.57), p(0.94, 0.49), p(0.82, 0.38),
            p(0.72, 0.20), p(0.50, 0.10), p(0.28, 0.20)
        ]),
        puzzle("rabbit", "Rabbit", "🐰", .numberTrail, .aqua, [
            p(0.31, 0.34), p(0.25, 0.08), p(0.39, 0.28), p(0.45, 0.08),
            p(0.50, 0.35), p(0.66, 0.44), p(0.79, 0.63), p(0.91, 0.64),
            p(0.81, 0.76), p(0.67, 0.78), p(0.58, 0.93), p(0.43, 0.78),
            p(0.24, 0.82), p(0.12, 0.66), p(0.24, 0.49)
        ]),
        puzzle("duck", "Duck", "🦆", .numberTrail, .gold, [
            p(0.18, 0.50), p(0.08, 0.42), p(0.22, 0.37), p(0.25, 0.18),
            p(0.42, 0.10), p(0.55, 0.22), p(0.52, 0.38), p(0.79, 0.43),
            p(0.93, 0.34), p(0.87, 0.55), p(0.76, 0.72), p(0.56, 0.84),
            p(0.34, 0.79), p(0.18, 0.68)
        ]),
        puzzle("snail", "Snail", "🐌", .numberTrail, .lime, [
            p(0.09, 0.70), p(0.18, 0.51), p(0.23, 0.23), p(0.43, 0.11),
            p(0.65, 0.19), p(0.75, 0.40), p(0.70, 0.61), p(0.84, 0.60),
            p(0.88, 0.39), p(0.93, 0.58), p(0.90, 0.76), p(0.68, 0.82),
            p(0.42, 0.78), p(0.25, 0.88)
        ]),
        puzzle("crown", "Crown", "👑", .numberTrail, .gold, [
            p(0.11, 0.28), p(0.29, 0.48), p(0.36, 0.13), p(0.50, 0.45),
            p(0.64, 0.13), p(0.71, 0.48), p(0.89, 0.28), p(0.81, 0.82),
            p(0.19, 0.82)
        ]),
        puzzle("dolphin", "Dolphin", "🐬", .numberTrail, .sky, [
            p(0.08, 0.52), p(0.27, 0.37), p(0.45, 0.20), p(0.60, 0.10),
            p(0.57, 0.31), p(0.76, 0.27), p(0.92, 0.36), p(0.78, 0.50),
            p(0.67, 0.65), p(0.82, 0.84), p(0.55, 0.72), p(0.37, 0.78),
            p(0.20, 0.69)
        ]),
        puzzle("penguin", "Penguin", "🐧", .numberTrail, .aqua, [
            p(0.50, 0.07), p(0.67, 0.16), p(0.73, 0.35), p(0.88, 0.57),
            p(0.72, 0.61), p(0.69, 0.83), p(0.82, 0.92), p(0.57, 0.89),
            p(0.50, 0.96), p(0.43, 0.89), p(0.18, 0.92), p(0.31, 0.83),
            p(0.28, 0.61), p(0.12, 0.57), p(0.27, 0.35), p(0.33, 0.16)
        ]),

        puzzle("dinosaur", "Long-neck Dinosaur", "🦕", .bigNumberAdventure, .lime, [
            p(0.05, 0.48), p(0.24, 0.36), p(0.45, 0.31), p(0.58, 0.28),
            p(0.61, 0.16), p(0.65, 0.07), p(0.78, 0.06), p(0.87, 0.11),
            p(0.88, 0.20), p(0.78, 0.24), p(0.71, 0.20), p(0.69, 0.39),
            p(0.78, 0.47), p(0.78, 0.83), p(0.68, 0.83), p(0.66, 0.59),
            p(0.50, 0.61), p(0.44, 0.86), p(0.34, 0.86), p(0.36, 0.59),
            p(0.22, 0.55), p(0.08, 0.56)
        ], guides: [
            [p(0.72, 0.14), p(0.75, 0.14)],
            [p(0.73, 0.19), p(0.78, 0.20), p(0.82, 0.18)]
        ], details: [
            [p(0.32, 0.42), p(0.36, 0.38), p(0.40, 0.43), p(0.36, 0.47), p(0.32, 0.42)],
            [p(0.45, 0.39), p(0.49, 0.36), p(0.53, 0.41), p(0.49, 0.45), p(0.45, 0.39)]
        ]),
        puzzle("whale", "Whale", "🐋", .numberExplorer, .sky, [
            p(0.08, 0.54), p(0.19, 0.33), p(0.38, 0.20), p(0.58, 0.21),
            p(0.74, 0.31), p(0.84, 0.19), p(0.93, 0.11), p(0.90, 0.36),
            p(0.79, 0.52), p(0.91, 0.63), p(0.74, 0.64), p(0.61, 0.78),
            p(0.39, 0.86), p(0.20, 0.76)
        ]),
        puzzle("elephant", "Elephant", "🐘", .numberExplorer, .violet, [
            p(0.08, 0.52), p(0.18, 0.40), p(0.25, 0.25), p(0.50, 0.18),
            p(0.68, 0.24), p(0.77, 0.34), p(0.88, 0.31), p(0.95, 0.40),
            p(0.89, 0.48), p(0.91, 0.70), p(0.84, 0.82), p(0.76, 0.76),
            p(0.78, 0.58), p(0.68, 0.55), p(0.65, 0.90), p(0.53, 0.90),
            p(0.50, 0.62), p(0.32, 0.62), p(0.29, 0.90), p(0.17, 0.90),
            p(0.18, 0.60), p(0.08, 0.64)
        ]),
        puzzle("giraffe", "Giraffe", "🦒", .numberExplorer, .gold, [
            p(0.31, 0.91), p(0.28, 0.61), p(0.37, 0.43), p(0.39, 0.17),
            p(0.31, 0.08), p(0.43, 0.12), p(0.50, 0.05), p(0.57, 0.13),
            p(0.72, 0.12), p(0.79, 0.22), p(0.66, 0.35), p(0.58, 0.34),
            p(0.56, 0.60), p(0.69, 0.90), p(0.56, 0.93), p(0.49, 0.69),
            p(0.43, 0.93)
        ]),
        puzzle("lion", "Lion", "🦁", .numberExplorer, .coral, [
            p(0.50, 0.05), p(0.61, 0.16), p(0.78, 0.10), p(0.80, 0.29),
            p(0.94, 0.40), p(0.82, 0.54), p(0.87, 0.74), p(0.67, 0.76),
            p(0.56, 0.94), p(0.40, 0.82), p(0.24, 0.91), p(0.20, 0.71),
            p(0.06, 0.58), p(0.18, 0.43), p(0.14, 0.24), p(0.34, 0.22)
        ]),
        puzzle("crab", "Crab", "🦀", .numberExplorer, .coral, [
            p(0.26, 0.42), p(0.11, 0.25), p(0.08, 0.45), p(0.21, 0.58),
            p(0.07, 0.72), p(0.28, 0.76), p(0.35, 0.91), p(0.45, 0.77),
            p(0.55, 0.77), p(0.65, 0.91), p(0.72, 0.76), p(0.93, 0.72),
            p(0.79, 0.58), p(0.92, 0.45), p(0.89, 0.25), p(0.74, 0.42),
            p(0.64, 0.22), p(0.36, 0.22)
        ]),
        puzzle("airplane", "Airplane", "✈️", .numberExplorer, .sky, [
            p(0.50, 0.05), p(0.60, 0.36), p(0.91, 0.54), p(0.90, 0.66),
            p(0.60, 0.56), p(0.58, 0.81), p(0.72, 0.91), p(0.70, 0.96),
            p(0.50, 0.87), p(0.30, 0.96), p(0.28, 0.91), p(0.42, 0.81),
            p(0.40, 0.56), p(0.10, 0.66), p(0.09, 0.54), p(0.40, 0.36)
        ]),
        puzzle("octopus", "Octopus", "🐙", .numberExplorer, .violet, [
            p(0.50, 0.08), p(0.68, 0.14), p(0.78, 0.31), p(0.77, 0.51),
            p(0.90, 0.73), p(0.76, 0.91), p(0.64, 0.72), p(0.58, 0.93),
            p(0.50, 0.74), p(0.42, 0.93), p(0.36, 0.72), p(0.24, 0.91),
            p(0.10, 0.73), p(0.23, 0.51), p(0.22, 0.31), p(0.32, 0.14)
        ]),
        puzzle("shark", "Shark", "🦈", .numberExplorer, .aqua, [
            p(0.06, 0.52), p(0.22, 0.33), p(0.43, 0.24), p(0.57, 0.08),
            p(0.65, 0.28), p(0.81, 0.36), p(0.95, 0.23), p(0.88, 0.52),
            p(0.95, 0.81), p(0.81, 0.68), p(0.65, 0.72), p(0.53, 0.91),
            p(0.44, 0.72), p(0.23, 0.67)
        ]),
        puzzle("robot", "Robot", "🤖", .numberExplorer, .violet, [
            p(0.50, 0.06), p(0.50, 0.15), p(0.75, 0.15), p(0.75, 0.29),
            p(0.84, 0.29), p(0.84, 0.62), p(0.73, 0.62), p(0.73, 0.91),
            p(0.58, 0.91), p(0.58, 0.72), p(0.42, 0.72), p(0.42, 0.91),
            p(0.27, 0.91), p(0.27, 0.62), p(0.16, 0.62), p(0.16, 0.29),
            p(0.25, 0.29), p(0.25, 0.15), p(0.45, 0.15)
        ])
    ]

    /// The reference-sheet pack is deliberately first so its new pictures are immediately visible
    /// in each number range. Classic IDs remain unchanged, preserving existing child progress.
    static let all: [DotPuzzle] = downloadedReferencePuzzles + classicPuzzles

    static var classicPuzzles: [DotPuzzle] {
        originalPuzzles
        + additionalFirstDots
        + additionalNumberTrails
        + additionalNumberExplorers
    }

    private static let additionalFirstDots: [DotPuzzle] = [
        // MARK: 1–10 — bold, familiar shapes with the gentlest numeral range
        puzzle("sun", "Sun", "☀️", .firstDots, .gold, [
            p(0.50, 0.05), p(0.59, 0.27), p(0.78, 0.12), p(0.73, 0.34), p(0.95, 0.31), p(0.76, 0.50), p(0.94, 0.69), p(0.72, 0.66), p(0.78, 0.89), p(0.59, 0.73), p(0.50, 0.95), p(0.41, 0.73), p(0.22, 0.89), p(0.28, 0.66), p(0.06, 0.69), p(0.24, 0.50), p(0.05, 0.31), p(0.27, 0.34), p(0.22, 0.12), p(0.41, 0.27)
        ]),
        puzzle("cloud", "Cloud", "☁️", .firstDots, .sky, [
            p(0.12, 0.70), p(0.06, 0.56), p(0.14, 0.43), p(0.29, 0.42), p(0.33, 0.22), p(0.50, 0.12), p(0.67, 0.22), p(0.72, 0.39), p(0.86, 0.40), p(0.95, 0.55), p(0.89, 0.72), p(0.70, 0.78), p(0.46, 0.77), p(0.25, 0.79)
        ]),
        puzzle("tree", "Fir Tree", "🌲", .firstDots, .lime, [
            p(0.42, 0.92), p(0.42, 0.70), p(0.20, 0.72), p(0.27, 0.56), p(0.11, 0.53), p(0.25, 0.36), p(0.17, 0.29), p(0.38, 0.22), p(0.50, 0.06), p(0.62, 0.22), p(0.83, 0.29), p(0.75, 0.36), p(0.89, 0.53), p(0.73, 0.56), p(0.80, 0.72), p(0.58, 0.70), p(0.58, 0.92)
        ]),
        puzzle("apple", "Apple", "🍎", .firstDots, .coral, [
            p(0.51, 0.20), p(0.57, 0.08), p(0.72, 0.06), p(0.65, 0.19), p(0.82, 0.22), p(0.92, 0.40), p(0.86, 0.65), p(0.70, 0.87), p(0.52, 0.94), p(0.34, 0.87), p(0.14, 0.65), p(0.08, 0.40), p(0.18, 0.22), p(0.36, 0.18)
        ]),
        puzzle("pear", "Pear", "🍐", .firstDots, .lime, [
            p(0.50, 0.06), p(0.62, 0.11), p(0.57, 0.27), p(0.70, 0.39), p(0.85, 0.57), p(0.84, 0.77), p(0.70, 0.91), p(0.50, 0.96), p(0.30, 0.91), p(0.16, 0.77), p(0.15, 0.57), p(0.30, 0.39), p(0.43, 0.27), p(0.41, 0.13)
        ]),
        puzzle("strawberry", "Strawberry", "🍓", .firstDots, .coral, [
            p(0.50, 0.13), p(0.37, 0.05), p(0.39, 0.20), p(0.22, 0.14), p(0.29, 0.30), p(0.14, 0.35), p(0.21, 0.61), p(0.34, 0.80), p(0.50, 0.95), p(0.66, 0.80), p(0.79, 0.61), p(0.86, 0.35), p(0.71, 0.30), p(0.78, 0.14), p(0.61, 0.20), p(0.63, 0.05)
        ]),
        puzzle("watermelon", "Watermelon", "🍉", .firstDots, .lime, [
            p(0.08, 0.68), p(0.12, 0.48), p(0.23, 0.26), p(0.40, 0.13),
            p(0.60, 0.13), p(0.77, 0.26), p(0.88, 0.48), p(0.92, 0.68),
            p(0.70, 0.68), p(0.50, 0.68), p(0.30, 0.68)
        ]),
        puzzle("cupcake", "Cupcake", "🧁", .firstDots, .violet, [
            p(0.24, 0.40), p(0.16, 0.31), p(0.22, 0.18), p(0.37, 0.16), p(0.45, 0.07), p(0.58, 0.15), p(0.73, 0.16), p(0.84, 0.30), p(0.76, 0.40), p(0.69, 0.90), p(0.31, 0.90)
        ]),
        puzzle("pizza", "Pizza", "🍕", .firstDots, .gold, [
            p(0.50, 0.07), p(0.92, 0.76), p(0.80, 0.90), p(0.64, 0.82), p(0.50, 0.93), p(0.36, 0.82), p(0.20, 0.90), p(0.08, 0.76)
        ]),
        puzzle("umbrella", "Umbrella", "☂️", .firstDots, .sky, [
            p(0.07, 0.49), p(0.16, 0.27), p(0.35, 0.12), p(0.50, 0.08), p(0.65, 0.12), p(0.84, 0.27), p(0.93, 0.49), p(0.74, 0.42), p(0.58, 0.49), p(0.52, 0.44), p(0.52, 0.82), p(0.61, 0.91), p(0.72, 0.84), p(0.66, 0.95), p(0.50, 0.92), p(0.45, 0.82), p(0.45, 0.44), p(0.34, 0.49), p(0.22, 0.42)
        ]),
        puzzle("balloon", "Balloon", "🎈", .firstDots, .coral, [
            p(0.50, 0.06), p(0.70, 0.13), p(0.82, 0.31), p(0.80, 0.52), p(0.65, 0.69), p(0.54, 0.77), p(0.58, 0.84), p(0.51, 0.82), p(0.60, 0.94), p(0.48, 0.87), p(0.42, 0.94), p(0.47, 0.82), p(0.40, 0.84), p(0.46, 0.77), p(0.35, 0.69), p(0.20, 0.52), p(0.18, 0.31), p(0.30, 0.13)
        ]),
        puzzle("present", "Present", "🎁", .firstDots, .violet, [
            p(0.10, 0.36), p(0.43, 0.36), p(0.25, 0.20), p(0.31, 0.09), p(0.47, 0.31), p(0.50, 0.12), p(0.53, 0.31), p(0.69, 0.09), p(0.75, 0.20), p(0.57, 0.36), p(0.90, 0.36), p(0.90, 0.53), p(0.84, 0.53), p(0.84, 0.91), p(0.16, 0.91), p(0.16, 0.53), p(0.10, 0.53)
        ]),
        puzzle("bell", "Bell", "🔔", .firstDots, .gold, [
            p(0.50, 0.06), p(0.58, 0.15), p(0.70, 0.21), p(0.77, 0.37), p(0.78, 0.61), p(0.91, 0.78), p(0.61, 0.81), p(0.58, 0.92), p(0.42, 0.92), p(0.39, 0.81), p(0.09, 0.78), p(0.22, 0.61), p(0.23, 0.37), p(0.30, 0.21), p(0.42, 0.15)
        ]),
        puzzle("key", "Key", "🔑", .firstDots, .gold, [
            p(0.13, 0.21), p(0.28, 0.10), p(0.43, 0.15), p(0.50, 0.29), p(0.45, 0.43), p(0.92, 0.78), p(0.82, 0.92), p(0.69, 0.82), p(0.61, 0.89), p(0.51, 0.78), p(0.43, 0.84), p(0.31, 0.68), p(0.38, 0.54), p(0.25, 0.50), p(0.11, 0.42)
        ]),
        puzzle("snowman", "Snowman", "⛄️", .firstDots, .sky, [
            p(0.50, 0.05), p(0.68, 0.14), p(0.70, 0.34), p(0.63, 0.43),
            p(0.82, 0.61), p(0.77, 0.88), p(0.50, 0.96), p(0.23, 0.88),
            p(0.18, 0.61), p(0.37, 0.43)
        ]),
        puzzle("mountain", "Mountain", "🏔️", .firstDots, .sky, [
            p(0.05, 0.88), p(0.27, 0.53), p(0.38, 0.67), p(0.55, 0.12), p(0.70, 0.48), p(0.79, 0.38), p(0.95, 0.88), p(0.70, 0.88), p(0.51, 0.88), p(0.28, 0.88)
        ]),
        puzzle("rainbow", "Rainbow", "🌈", .firstDots, .violet, [
            p(0.07, 0.83), p(0.09, 0.54), p(0.21, 0.29), p(0.40, 0.14), p(0.60, 0.14), p(0.79, 0.29), p(0.91, 0.54), p(0.93, 0.83), p(0.72, 0.83), p(0.70, 0.59), p(0.61, 0.44), p(0.50, 0.38), p(0.39, 0.44), p(0.30, 0.59), p(0.28, 0.83)
        ]),
        puzzle("castle", "Castle", "🏰", .firstDots, .violet, [
            p(0.10, 0.91), p(0.10, 0.25), p(0.21, 0.25), p(0.21, 0.12), p(0.34, 0.12), p(0.34, 0.31), p(0.43, 0.31), p(0.43, 0.18), p(0.57, 0.18), p(0.57, 0.31), p(0.66, 0.31), p(0.66, 0.12), p(0.79, 0.12), p(0.79, 0.25), p(0.90, 0.25), p(0.90, 0.91), p(0.61, 0.91), p(0.61, 0.68), p(0.50, 0.57), p(0.39, 0.68), p(0.39, 0.91)
        ]),
        puzzle("lighthouse", "Lighthouse", "💡", .firstDots, .coral, [
            p(0.31, 0.91), p(0.38, 0.35), p(0.28, 0.35), p(0.37, 0.17),
            p(0.44, 0.08), p(0.56, 0.08), p(0.63, 0.17), p(0.72, 0.35),
            p(0.62, 0.35), p(0.69, 0.91)
        ]),
        puzzle("anchor", "Anchor", "⚓️", .firstDots, .aqua, [
            p(0.50, 0.06), p(0.62, 0.18), p(0.55, 0.31), p(0.56, 0.66),
            p(0.90, 0.57), p(0.82, 0.88), p(0.50, 0.96), p(0.18, 0.88),
            p(0.10, 0.57), p(0.44, 0.66)
        ]),
        puzzle("shell", "Seashell", "🐚", .firstDots, .coral, [
            p(0.50, 0.95), p(0.32, 0.82), p(0.13, 0.88), p(0.15, 0.65),
            p(0.07, 0.53), p(0.18, 0.35), p(0.26, 0.18), p(0.38, 0.27),
            p(0.50, 0.07), p(0.62, 0.27), p(0.74, 0.18), p(0.82, 0.35),
            p(0.93, 0.53), p(0.85, 0.65), p(0.87, 0.88), p(0.68, 0.82)
        ]),
        puzzle("music-note", "Music Note", "🎵", .firstDots, .violet, [
            p(0.40, 0.20), p(0.82, 0.08), p(0.82, 0.62), p(0.72, 0.55), p(0.58, 0.58), p(0.50, 0.69), p(0.54, 0.82), p(0.69, 0.88), p(0.82, 0.81), p(0.88, 0.69), p(0.88, 0.05), p(0.34, 0.20), p(0.34, 0.68), p(0.24, 0.62), p(0.10, 0.66), p(0.06, 0.79), p(0.14, 0.90), p(0.29, 0.91), p(0.40, 0.81)
        ]),
        puzzle("book", "Book", "📖", .firstDots, .sky, [
            p(0.08, 0.19), p(0.28, 0.13), p(0.50, 0.24), p(0.72, 0.13), p(0.92, 0.19), p(0.92, 0.84), p(0.72, 0.78), p(0.50, 0.89), p(0.28, 0.78), p(0.08, 0.84)
        ]),
        puzzle("pencil", "Pencil", "✏️", .firstDots, .gold, [
            p(0.08, 0.80), p(0.20, 0.53), p(0.67, 0.08), p(0.83, 0.10), p(0.92, 0.24), p(0.45, 0.70), p(0.18, 0.92)
        ]),

    ]

    private static let additionalNumberTrails: [DotPuzzle] = [
        // MARK: 1–15 — expressive animals with richer numeral trails
        puzzle("fox", "Fox", "🦊", .numberTrail, .coral, [
            p(0.18, 0.19), p(0.36, 0.29), p(0.50, 0.20), p(0.64, 0.29), p(0.82, 0.19), p(0.77, 0.48), p(0.89, 0.66), p(0.68, 0.72), p(0.57, 0.91), p(0.50, 0.79), p(0.43, 0.91), p(0.32, 0.72), p(0.11, 0.66), p(0.23, 0.48)
        ]),
        puzzle("bear", "Bear", "🐻", .numberTrail, .gold, [
            p(0.24, 0.27), p(0.16, 0.13), p(0.32, 0.10), p(0.40, 0.20), p(0.60, 0.20), p(0.68, 0.10), p(0.84, 0.13), p(0.76, 0.27), p(0.84, 0.48), p(0.75, 0.71), p(0.61, 0.84), p(0.50, 0.94), p(0.39, 0.84), p(0.25, 0.71), p(0.16, 0.48)
        ]),
        puzzle("panda", "Panda", "🐼", .numberTrail, .aqua, [
            p(0.26, 0.28), p(0.13, 0.19), p(0.20, 0.07), p(0.34, 0.14),
            p(0.50, 0.10), p(0.66, 0.14), p(0.80, 0.07), p(0.87, 0.19),
            p(0.74, 0.28), p(0.78, 0.42), p(0.91, 0.56), p(0.82, 0.70),
            p(0.70, 0.62), p(0.70, 0.90), p(0.56, 0.90), p(0.50, 0.74),
            p(0.44, 0.90), p(0.30, 0.90), p(0.30, 0.62), p(0.18, 0.70),
            p(0.09, 0.56), p(0.22, 0.42)
        ]),
        puzzle("koala", "Koala", "🐨", .numberTrail, .aqua, [
            p(0.24, 0.28), p(0.11, 0.25), p(0.08, 0.10), p(0.24, 0.08), p(0.35, 0.20), p(0.65, 0.20), p(0.76, 0.08), p(0.92, 0.10), p(0.89, 0.25), p(0.76, 0.28), p(0.83, 0.54), p(0.70, 0.78), p(0.50, 0.93), p(0.30, 0.78), p(0.17, 0.54)
        ]),
        puzzle("monkey", "Monkey", "🐵", .numberTrail, .gold, [
            p(0.25, 0.27), p(0.10, 0.31), p(0.07, 0.50), p(0.18, 0.62), p(0.27, 0.58), p(0.31, 0.77), p(0.50, 0.91), p(0.69, 0.77), p(0.73, 0.58), p(0.82, 0.62), p(0.93, 0.50), p(0.90, 0.31), p(0.75, 0.27), p(0.66, 0.10), p(0.50, 0.05), p(0.34, 0.10)
        ]),
        puzzle("frog", "Frog", "🐸", .numberTrail, .lime, [
            p(0.21, 0.32), p(0.13, 0.18), p(0.27, 0.10), p(0.39, 0.22), p(0.61, 0.22), p(0.73, 0.10), p(0.87, 0.18), p(0.79, 0.32), p(0.89, 0.51), p(0.76, 0.73), p(0.61, 0.84), p(0.50, 0.94), p(0.39, 0.84), p(0.24, 0.73), p(0.11, 0.51)
        ]),
        puzzle("owl", "Owl", "🦉", .numberTrail, .violet, [
            p(0.20, 0.16), p(0.38, 0.25), p(0.50, 0.11), p(0.62, 0.25), p(0.80, 0.16), p(0.76, 0.43), p(0.89, 0.61), p(0.72, 0.69), p(0.65, 0.91), p(0.50, 0.80), p(0.35, 0.91), p(0.28, 0.69), p(0.11, 0.61), p(0.24, 0.43)
        ]),
        puzzle("chicken", "Chicken", "🐔", .numberTrail, .coral, [
            p(0.44, 0.17), p(0.48, 0.06), p(0.55, 0.16), p(0.63, 0.08), p(0.66, 0.21), p(0.84, 0.28), p(0.71, 0.38), p(0.83, 0.58), p(0.70, 0.78), p(0.53, 0.89), p(0.31, 0.84), p(0.17, 0.65), p(0.16, 0.42), p(0.29, 0.25)
        ]),
        puzzle("pig", "Pig", "🐷", .numberTrail, .coral, [
            p(0.25, 0.27), p(0.18, 0.11), p(0.37, 0.21), p(0.63, 0.21), p(0.82, 0.11), p(0.75, 0.27), p(0.88, 0.43), p(0.82, 0.66), p(0.65, 0.82), p(0.50, 0.92), p(0.35, 0.82), p(0.18, 0.66), p(0.12, 0.43)
        ]),
        puzzle("cow", "Cow", "🐮", .numberTrail, .aqua, [
            p(0.21, 0.30), p(0.08, 0.18), p(0.28, 0.20), p(0.34, 0.08), p(0.43, 0.22), p(0.57, 0.22), p(0.66, 0.08), p(0.72, 0.20), p(0.92, 0.18), p(0.79, 0.30), p(0.84, 0.56), p(0.70, 0.78), p(0.50, 0.92), p(0.30, 0.78), p(0.16, 0.56)
        ]),
        puzzle("sheep", "Sheep", "🐑", .numberTrail, .sky, [
            p(0.17, 0.45), p(0.08, 0.31), p(0.20, 0.18), p(0.36, 0.20), p(0.46, 0.08), p(0.59, 0.19), p(0.75, 0.14), p(0.82, 0.28), p(0.93, 0.39), p(0.83, 0.55), p(0.86, 0.73), p(0.68, 0.79), p(0.58, 0.92), p(0.42, 0.82), p(0.25, 0.87), p(0.18, 0.70), p(0.07, 0.59)
        ]),
        puzzle("horse", "Horse", "🐴", .numberTrail, .gold, [
            p(0.27, 0.22), p(0.21, 0.07), p(0.38, 0.18), p(0.55, 0.11), p(0.73, 0.20), p(0.83, 0.36), p(0.76, 0.54), p(0.84, 0.69), p(0.68, 0.88), p(0.49, 0.92), p(0.37, 0.76), p(0.22, 0.73), p(0.13, 0.54), p(0.18, 0.37)
        ]),
        puzzle("zebra", "Zebra", "🦓", .numberTrail, .aqua, [
            p(0.07, 0.48), p(0.19, 0.36), p(0.25, 0.18), p(0.34, 0.31),
            p(0.68, 0.31), p(0.78, 0.22), p(0.76, 0.39), p(0.93, 0.50),
            p(0.78, 0.56), p(0.74, 0.90), p(0.61, 0.90), p(0.59, 0.60),
            p(0.39, 0.60), p(0.36, 0.90), p(0.23, 0.90), p(0.20, 0.58),
            p(0.08, 0.58)
        ]),
        puzzle("camel", "Camel", "🐪", .numberTrail, .gold, [
            p(0.08, 0.73), p(0.16, 0.42), p(0.29, 0.36), p(0.38, 0.17), p(0.50, 0.34), p(0.61, 0.15), p(0.72, 0.37), p(0.82, 0.30), p(0.90, 0.39), p(0.84, 0.58), p(0.75, 0.66), p(0.79, 0.91), p(0.66, 0.91), p(0.60, 0.69), p(0.35, 0.69), p(0.30, 0.92), p(0.17, 0.91), p(0.20, 0.66)
        ]),
        puzzle("crocodile", "Crocodile", "🐊", .numberTrail, .lime, [
            p(0.05, 0.52), p(0.22, 0.35), p(0.38, 0.31), p(0.47, 0.17), p(0.56, 0.31), p(0.68, 0.20), p(0.74, 0.36), p(0.94, 0.43), p(0.82, 0.53), p(0.94, 0.64), p(0.71, 0.68), p(0.61, 0.83), p(0.50, 0.69), p(0.36, 0.82), p(0.30, 0.66), p(0.15, 0.64)
        ]),
        puzzle("seahorse", "Seahorse", "🐚", .numberTrail, .aqua, [
            p(0.55, 0.06), p(0.72, 0.13), p(0.77, 0.27), p(0.68, 0.39), p(0.79, 0.50), p(0.66, 0.63), p(0.63, 0.78), p(0.73, 0.88), p(0.62, 0.96), p(0.49, 0.88), p(0.48, 0.72), p(0.36, 0.64), p(0.27, 0.50), p(0.37, 0.38), p(0.34, 0.23), p(0.43, 0.11)
        ]),
        puzzle("jellyfish", "Jellyfish", "🌊", .numberTrail, .violet, [
            p(0.14, 0.51), p(0.19, 0.28), p(0.35, 0.11), p(0.50, 0.06), p(0.65, 0.11), p(0.81, 0.28), p(0.86, 0.51), p(0.74, 0.47), p(0.79, 0.89), p(0.66, 0.73), p(0.58, 0.94), p(0.50, 0.71), p(0.42, 0.94), p(0.34, 0.73), p(0.21, 0.89), p(0.26, 0.47)
        ]),
        puzzle("bee", "Bumblebee", "🐝", .numberTrail, .gold, [
            p(0.29, 0.37), p(0.13, 0.21), p(0.31, 0.17), p(0.43, 0.31), p(0.57, 0.31), p(0.69, 0.17), p(0.87, 0.21), p(0.71, 0.37), p(0.87, 0.50), p(0.72, 0.68), p(0.56, 0.75), p(0.50, 0.91), p(0.44, 0.75), p(0.28, 0.68), p(0.13, 0.50)
        ]),
        puzzle("ladybird", "Ladybird", "🐞", .numberTrail, .coral, [
            p(0.42, 0.19), p(0.36, 0.07), p(0.46, 0.17), p(0.54, 0.17), p(0.64, 0.07), p(0.58, 0.19), p(0.75, 0.29), p(0.84, 0.48), p(0.79, 0.69), p(0.64, 0.87), p(0.50, 0.94), p(0.36, 0.87), p(0.21, 0.69), p(0.16, 0.48), p(0.25, 0.29)
        ]),
        puzzle("spider", "Spider", "🕷️", .numberTrail, .violet, [
            p(0.38, 0.31), p(0.23, 0.18), p(0.07, 0.22), p(0.27, 0.38), p(0.07, 0.47), p(0.29, 0.52), p(0.12, 0.72), p(0.36, 0.61), p(0.43, 0.88), p(0.50, 0.70), p(0.57, 0.88), p(0.64, 0.61), p(0.88, 0.72), p(0.71, 0.52), p(0.93, 0.47), p(0.73, 0.38), p(0.93, 0.22), p(0.77, 0.18), p(0.62, 0.31), p(0.50, 0.16)
        ]),
        puzzle("mouse", "Mouse", "🐭", .numberTrail, .aqua, [
            p(0.23, 0.31), p(0.10, 0.26), p(0.13, 0.10), p(0.30, 0.13), p(0.39, 0.24), p(0.61, 0.24), p(0.70, 0.13), p(0.87, 0.10), p(0.90, 0.26), p(0.77, 0.31), p(0.84, 0.54), p(0.70, 0.74), p(0.55, 0.81), p(0.50, 0.94), p(0.45, 0.81), p(0.30, 0.74), p(0.16, 0.54)
        ]),
        puzzle("squirrel", "Squirrel", "🐿️", .numberTrail, .gold, [
            p(0.92, 0.39), p(0.76, 0.35), p(0.70, 0.20), p(0.62, 0.35),
            p(0.65, 0.55), p(0.80, 0.72), p(0.62, 0.76), p(0.55, 0.92),
            p(0.38, 0.82), p(0.30, 0.68), p(0.15, 0.78), p(0.08, 0.55),
            p(0.15, 0.25), p(0.35, 0.10), p(0.50, 0.32)
        ]),
        puzzle("hedgehog", "Hedgehog", "🦔", .numberTrail, .gold, [
            p(0.94, 0.56), p(0.78, 0.70), p(0.68, 0.86), p(0.52, 0.78),
            p(0.40, 0.90), p(0.25, 0.80), p(0.10, 0.65), p(0.18, 0.53),
            p(0.08, 0.40), p(0.25, 0.43), p(0.21, 0.24), p(0.39, 0.32),
            p(0.50, 0.14), p(0.62, 0.34), p(0.78, 0.37)
        ]),

    ]

    private static let additionalNumberExplorers: [DotPuzzle] = [
        // MARK: 1–20 — richer silhouettes and the busiest numeral field
        puzzle("car", "Car", "🚗", .numberExplorer, .coral, [
            p(0.08, 0.70), p(0.10, 0.49), p(0.24, 0.43), p(0.35, 0.24), p(0.66, 0.24), p(0.79, 0.43), p(0.92, 0.50), p(0.92, 0.70), p(0.81, 0.70), p(0.77, 0.86), p(0.62, 0.86), p(0.58, 0.70), p(0.40, 0.70), p(0.36, 0.86), p(0.21, 0.86), p(0.17, 0.70)
        ]),
        puzzle("bus", "Bus", "🚌", .numberExplorer, .gold, [
            p(0.10, 0.80), p(0.10, 0.21), p(0.20, 0.10), p(0.80, 0.10), p(0.90, 0.21), p(0.90, 0.80), p(0.79, 0.80), p(0.75, 0.92), p(0.62, 0.92), p(0.58, 0.80), p(0.40, 0.80), p(0.36, 0.92), p(0.23, 0.92), p(0.19, 0.80)
        ]),
        puzzle("train", "Train", "🚂", .numberExplorer, .sky, [
            p(0.08, 0.78), p(0.08, 0.45), p(0.31, 0.45), p(0.31, 0.18), p(0.58, 0.18), p(0.58, 0.38), p(0.72, 0.38), p(0.82, 0.51), p(0.93, 0.55), p(0.93, 0.78), p(0.84, 0.78), p(0.80, 0.91), p(0.65, 0.91), p(0.61, 0.78), p(0.37, 0.78), p(0.33, 0.91), p(0.18, 0.91), p(0.14, 0.78)
        ]),
        puzzle("saturn", "Ringed Planet", "🪐", .numberExplorer, .aqua, [
            p(0.05, 0.38), p(0.30, 0.34), p(0.35, 0.20), p(0.50, 0.08),
            p(0.65, 0.20), p(0.70, 0.34), p(0.95, 0.38), p(0.76, 0.50),
            p(0.70, 0.66), p(0.64, 0.82), p(0.50, 0.92), p(0.36, 0.82),
            p(0.30, 0.66), p(0.24, 0.50)
        ]),
        puzzle("tractor", "Tractor", "🚜", .numberExplorer, .lime, [
            p(0.08, 0.70), p(0.16, 0.48), p(0.35, 0.43), p(0.39, 0.18), p(0.66, 0.18), p(0.72, 0.43), p(0.90, 0.51), p(0.92, 0.70), p(0.78, 0.70), p(0.74, 0.88), p(0.55, 0.88), p(0.50, 0.70), p(0.35, 0.70), p(0.30, 0.93), p(0.13, 0.93)
        ]),
        puzzle("fire-engine", "Fire Engine", "🚒", .numberExplorer, .coral, [
            p(0.07, 0.75), p(0.07, 0.43), p(0.28, 0.43), p(0.36, 0.24), p(0.64, 0.24), p(0.73, 0.43), p(0.88, 0.48), p(0.93, 0.75), p(0.83, 0.75), p(0.79, 0.90), p(0.64, 0.90), p(0.60, 0.75), p(0.37, 0.75), p(0.33, 0.90), p(0.18, 0.90), p(0.14, 0.75)
        ]),
        puzzle("submarine", "Submarine", "⚓️", .numberExplorer, .gold, [
            p(0.06, 0.58), p(0.20, 0.40), p(0.39, 0.34), p(0.43, 0.21), p(0.58, 0.21), p(0.62, 0.34), p(0.80, 0.40), p(0.94, 0.58), p(0.82, 0.73), p(0.61, 0.82), p(0.38, 0.82), p(0.18, 0.73)
        ]),
        puzzle("helicopter", "Helicopter", "🚁", .numberExplorer, .sky, [
            p(0.06, 0.53), p(0.22, 0.47), p(0.35, 0.31), p(0.62, 0.31), p(0.76, 0.45), p(0.92, 0.45), p(0.92, 0.55), p(0.76, 0.55), p(0.64, 0.70), p(0.38, 0.73), p(0.23, 0.65), p(0.13, 0.65), p(0.13, 0.57), p(0.06, 0.62), p(0.03, 0.58), p(0.13, 0.50)
        ]),
        puzzle("hot-air-balloon", "Hot-air Balloon", "🎈", .bigNumberAdventure, .violet, [
            p(0.50, 0.05), p(0.69, 0.12), p(0.82, 0.30), p(0.80, 0.51), p(0.66, 0.69), p(0.58, 0.76), p(0.62, 0.84), p(0.59, 0.95), p(0.41, 0.95), p(0.38, 0.84), p(0.42, 0.76), p(0.34, 0.69), p(0.20, 0.51), p(0.18, 0.30), p(0.31, 0.12)
        ]),
        puzzle("astronaut", "Astronaut", "🧑‍🚀", .bigNumberAdventure, .sky, [
            p(0.39, 0.08), p(0.61, 0.08), p(0.72, 0.17), p(0.75, 0.31),
            p(0.70, 0.41), p(0.78, 0.49), p(0.91, 0.66), p(0.82, 0.73),
            p(0.68, 0.57), p(0.65, 0.76), p(0.74, 0.91), p(0.62, 0.95),
            p(0.50, 0.78), p(0.38, 0.95), p(0.26, 0.91), p(0.35, 0.76),
            p(0.32, 0.57), p(0.18, 0.73), p(0.09, 0.66), p(0.22, 0.49),
            p(0.30, 0.41), p(0.25, 0.31), p(0.28, 0.17)
        ], guides: [
            [p(0.34, 0.20), p(0.40, 0.14), p(0.60, 0.14), p(0.66, 0.20), p(0.66, 0.31), p(0.59, 0.37), p(0.41, 0.37), p(0.34, 0.31), p(0.34, 0.20)],
            [p(0.39, 0.49), p(0.61, 0.49), p(0.61, 0.63), p(0.39, 0.63), p(0.39, 0.49)]
        ], details: [
            [p(0.43, 0.55), p(0.47, 0.55)],
            [p(0.53, 0.55), p(0.57, 0.55)],
            [p(0.47, 0.60), p(0.53, 0.60)]
        ]),
        puzzle("guitar", "Guitar", "🎸", .numberExplorer, .gold, [
            p(0.18, 0.75), p(0.10, 0.58), p(0.20, 0.42), p(0.36, 0.45), p(0.64, 0.12), p(0.82, 0.08), p(0.92, 0.18), p(0.88, 0.33), p(0.78, 0.35), p(0.53, 0.61), p(0.55, 0.79), p(0.38, 0.91)
        ]),
        puzzle("drum", "Drum", "🥁", .numberExplorer, .coral, [
            p(0.14, 0.32), p(0.28, 0.19), p(0.72, 0.19), p(0.86, 0.32), p(0.80, 0.78), p(0.65, 0.89), p(0.35, 0.89), p(0.20, 0.78)
        ]),
        puzzle("camera", "Camera", "📷", .numberExplorer, .sky, [
            p(0.09, 0.80), p(0.09, 0.31), p(0.30, 0.31), p(0.36, 0.18), p(0.64, 0.18), p(0.70, 0.31), p(0.91, 0.31), p(0.91, 0.80), p(0.70, 0.80), p(0.63, 0.90), p(0.37, 0.90), p(0.30, 0.80)
        ]),
        puzzle("teddy", "Teddy Bear", "🧸", .numberExplorer, .gold, [
            p(0.25, 0.28), p(0.12, 0.18), p(0.20, 0.07), p(0.35, 0.16), p(0.50, 0.10), p(0.65, 0.16), p(0.80, 0.07), p(0.88, 0.18), p(0.75, 0.28), p(0.78, 0.49), p(0.92, 0.62), p(0.82, 0.76), p(0.69, 0.70), p(0.72, 0.91), p(0.57, 0.89), p(0.50, 0.74), p(0.43, 0.89), p(0.28, 0.91), p(0.31, 0.70), p(0.18, 0.76), p(0.08, 0.62), p(0.22, 0.49)
        ]),
        puzzle("football", "Football", "⚽️", .numberExplorer, .aqua, [
            p(0.50, 0.06), p(0.68, 0.12), p(0.83, 0.25), p(0.92, 0.43), p(0.91, 0.62), p(0.80, 0.80), p(0.63, 0.91), p(0.43, 0.93), p(0.25, 0.83), p(0.12, 0.68), p(0.07, 0.49), p(0.14, 0.30), p(0.30, 0.15)
        ]),
        puzzle("treasure-map", "Treasure Map", "🗺️", .numberExplorer, .violet, [
            p(0.12, 0.18), p(0.32, 0.12), p(0.50, 0.18), p(0.68, 0.12),
            p(0.88, 0.19), p(0.82, 0.38), p(0.88, 0.57), p(0.81, 0.82),
            p(0.61, 0.87), p(0.50, 0.82), p(0.37, 0.89), p(0.13, 0.82),
            p(0.18, 0.62), p(0.11, 0.45)
        ]),
        puzzle("mermaid", "Mermaid", "🧜‍♀️", .bigNumberAdventure, .aqua, [
            p(0.50, 0.05), p(0.63, 0.10), p(0.67, 0.22), p(0.62, 0.31),
            p(0.82, 0.43), p(0.76, 0.52), p(0.61, 0.43), p(0.62, 0.57),
            p(0.55, 0.79), p(0.72, 0.92), p(0.50, 0.86), p(0.28, 0.92),
            p(0.45, 0.79), p(0.38, 0.57), p(0.39, 0.43), p(0.24, 0.52),
            p(0.18, 0.43), p(0.38, 0.31), p(0.33, 0.22), p(0.37, 0.10)
        ]),
        puzzle("dragon", "Dragon", "🐉", .bigNumberAdventure, .lime, [
            p(0.09, 0.70), p(0.20, 0.48), p(0.15, 0.27), p(0.34, 0.37), p(0.42, 0.17), p(0.53, 0.34), p(0.66, 0.13), p(0.71, 0.36), p(0.90, 0.28), p(0.82, 0.50), p(0.93, 0.64), p(0.73, 0.67), p(0.65, 0.88), p(0.51, 0.70), p(0.36, 0.91), p(0.31, 0.69), p(0.16, 0.84)
        ]),
        puzzle("unicorn", "Unicorn", "🦄", .bigNumberAdventure, .violet, [
            p(0.94, 0.37), p(0.84, 0.28), p(0.86, 0.06), p(0.75, 0.24),
            p(0.68, 0.13), p(0.61, 0.29), p(0.43, 0.30), p(0.26, 0.38),
            p(0.12, 0.28), p(0.05, 0.43), p(0.16, 0.52), p(0.25, 0.55),
            p(0.21, 0.89), p(0.33, 0.89), p(0.35, 0.61), p(0.55, 0.62),
            p(0.58, 0.90), p(0.70, 0.90), p(0.68, 0.60), p(0.74, 0.52),
            p(0.87, 0.46)
        ]),
        puzzle("pirate-ship", "Pirate Ship", "🏴‍☠️", .bigNumberAdventure, .gold, [
            p(0.08, 0.70), p(0.42, 0.70), p(0.42, 0.17), p(0.49, 0.17), p(0.49, 0.10), p(0.56, 0.17), p(0.82, 0.38), p(0.56, 0.58), p(0.56, 0.70), p(0.92, 0.70), p(0.79, 0.90), p(0.25, 0.90)
        ]),
        puzzle("treasure-chest", "Treasure Chest", "💰", .bigNumberAdventure, .gold, [
            p(0.10, 0.88), p(0.10, 0.42), p(0.18, 0.22), p(0.35, 0.10),
            p(0.65, 0.10), p(0.82, 0.22), p(0.90, 0.42), p(0.90, 0.88),
            p(0.65, 0.88), p(0.35, 0.88)
        ]),
        puzzle("excavator", "Digger", "🚧", .bigNumberAdventure, .gold, [
            p(0.08, 0.76), p(0.12, 0.52), p(0.33, 0.48), p(0.39, 0.24), p(0.64, 0.24), p(0.70, 0.49), p(0.77, 0.46), p(0.83, 0.23), p(0.91, 0.18), p(0.93, 0.31), p(0.84, 0.56), p(0.92, 0.67), p(0.82, 0.76), p(0.70, 0.76), p(0.66, 0.91), p(0.29, 0.91), p(0.24, 0.76)
        ]),
        puzzle("volcano", "Volcano", "🌋", .bigNumberAdventure, .coral, [
            p(0.07, 0.90), p(0.30, 0.57), p(0.40, 0.30), p(0.33, 0.18), p(0.45, 0.22), p(0.50, 0.06), p(0.55, 0.22), p(0.67, 0.18), p(0.60, 0.30), p(0.70, 0.57), p(0.93, 0.90), p(0.67, 0.90), p(0.50, 0.84), p(0.33, 0.90)
        ])
    ]

    static func puzzles(in tier: DotToDotTier) -> [DotPuzzle] {
        all.filter { $0.tier == tier }
    }

    private static func puzzle(
        _ id: String,
        _ title: String,
        _ emoji: String,
        _ tier: DotToDotTier,
        _ palette: DotPuzzlePalette,
        _ outline: [CGPoint],
        trail: [CGPoint]? = nil,
        guides: [[CGPoint]] = [],
        details: [[CGPoint]] = []
    ) -> DotPuzzle {
        DotPuzzle(
            id: id,
            title: title,
            emoji: emoji,
            tier: tier,
            palette: palette,
            outline: outline,
            trail: trail,
            guidePaths: guides,
            detailPaths: details
        )
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}

enum DotPuzzleGeometry {
    static let angularArtworkIDs: Set<String> = [
        "rocket", "star", "house", "sailboat", "kite", "crown", "robot", "sun",
        "tree", "pizza", "umbrella", "present", "key", "castle", "car", "bus",
        "train", "saturn", "tractor", "fire-engine", "submarine", "helicopter",
        "camera", "treasure-map", "pirate-ship", "treasure-chest", "excavator", "volcano"
    ]

    /// Samples the outline with deliberately varied spacing. Strong paper dot-to-dots do not look
    /// like a uniformly perforated polygon: important turns are separated by longer and shorter
    /// runs, so a child still has to scan the numerals instead of following equal gaps by eye.
    static func makeNumberTrail(
        _ rawPoints: [CGPoint],
        count: Int,
        puzzleID: String
    ) -> [CGPoint] {
        guard rawPoints.count >= 3, count > 0 else { return rawPoints }

        var controlPoints = rawPoints
        if controlPoints.first == controlPoints.last {
            controlPoints.removeLast()
        }

        // Tiny authored notches do not make useful child targets: their number circles overlap and
        // the turn cannot be traced reliably on an iPhone. Collapse only those sub-touch-target
        // vertices before assigning numerals; the resulting exterior still uses numbered points
        // exclusively.
        let minimumControlSpacing: CGFloat = switch count {
        case ...10: 0.075
        case ...15: 0.060
        case ...20: 0.052
        default: 0.045
        }
        var touchSafeControls: [CGPoint] = []
        for point in controlPoints {
            if let previous = touchSafeControls.last,
               distance(previous, point) < minimumControlSpacing {
                continue
            }
            touchSafeControls.append(point)
        }
        if touchSafeControls.count > 3,
           let first = touchSafeControls.first,
           let last = touchSafeControls.last,
           distance(first, last) < minimumControlSpacing {
            touchSafeControls.removeLast()
        }
        if touchSafeControls.count >= 3 {
            controlPoints = touchSafeControls
        }

        let segments = controlPoints.indices.map { index -> (CGPoint, CGPoint, CGFloat) in
            let start = controlPoints[index]
            let end = controlPoints[(index + 1) % controlPoints.count]
            return (start, end, distance(start, end))
        }
        let perimeter = segments.reduce(CGFloat.zero) { $0 + $1.2 }
        guard perimeter > 0 else { return Array(repeating: controlPoints[0], count: count) }

        // When the number range has enough capacity, retain every authored turn as a numbered dot
        // and distribute the remaining dots along the longest gaps. This preserves recognisable
        // corners without ever hiding one between numerals.
        if count >= controlPoints.count {
            var subdivisions = Array(repeating: 1, count: segments.count)
            var remaining = count - segments.count
            let seedOffset = stableSeed(for: puzzleID) % max(segments.count, 1)

            while remaining > 0 {
                let nextIndex = segments.indices.max { left, right in
                    let leftSpacing = segments[left].2 / CGFloat(subdivisions[left])
                    let rightSpacing = segments[right].2 / CGFloat(subdivisions[right])
                    if abs(leftSpacing - rightSpacing) > 0.000_001 {
                        return leftSpacing < rightSpacing
                    }
                    let leftOrder = (left - seedOffset + segments.count) % segments.count
                    let rightOrder = (right - seedOffset + segments.count) % segments.count
                    return leftOrder > rightOrder
                } ?? 0
                subdivisions[nextIndex] += 1
                remaining -= 1
            }

            return segments.indices.flatMap { index -> [CGPoint] in
                let segment = segments[index]
                return (0..<subdivisions[index]).map { division in
                    let progress = CGFloat(division) / CGFloat(subdivisions[index])
                    return CGPoint(
                        x: segment.0.x + (segment.1.x - segment.0.x) * progress,
                        y: segment.0.y + (segment.1.y - segment.0.y) * progress
                    )
                }
            }
        }

        let spacingPattern: [CGFloat] = [0.72, 1.38, 0.88, 1.20, 0.78, 1.46, 0.96, 1.12]
        let rotation = stableSeed(for: puzzleID) % spacingPattern.count
        var weights = (0..<count).map { index in
            spacingPattern[(index + rotation) % spacingPattern.count]
        }
        // Make the opening a genuine numeral-search moment on every closed picture: dot N sits
        // spatially nearer to dot 1 than dot 2, while only numeral recognition reveals the route.
        if count >= 3 {
            weights[0] = 1.46
            weights[count - 1] = 0.64
        }
        let totalWeight = weights.reduce(CGFloat.zero, +)
        var travelledWeight: CGFloat = 0

        return weights.map { weight in
            defer { travelledWeight += weight }
            var target = perimeter * travelledWeight / totalWeight
            for segment in segments {
                if target <= segment.2 {
                    let progress = segment.2 == 0 ? 0 : target / segment.2
                    return CGPoint(
                        x: segment.0.x + (segment.1.x - segment.0.x) * progress,
                        y: segment.0.y + (segment.1.y - segment.0.y) * progress
                    )
                }
                target -= segment.2
            }
            return controlPoints[0]
        }
    }

    /// Number of moments where at least one later dot is as plausible spatially as the true next
    /// dot. It is a QA signal, not a scoring rule: children are always helped by the spoken target.
    static func meaningfulChoiceCount(in points: [CGPoint]) -> Int {
        guard points.count >= 3 else { return 0 }
        return (0..<(points.count - 2)).reduce(into: 0) { count, index in
            let nextDistance = distance(points[index], points[index + 1])
            let hasPlausibleAlternative = points[(index + 2)...].contains {
                distance(points[index], $0) <= nextDistance * 1.18
            }
            if hasPlausibleAlternative { count += 1 }
        }
    }

    /// A closed perimeter has no intrinsic first point. Rotate numeral labels, without moving any
    /// artwork, until at least one step presents a plausible nearby alternative. This keeps every
    /// picture a numeral-recognition activity instead of a simple nearest-neighbour trail.
    static func withMeaningfulNumeralStart(_ points: [CGPoint]) -> [CGPoint] {
        guard meaningfulChoiceCount(in: points) == 0, points.count >= 3 else { return points }

        for offset in 1..<points.count {
            let rotated = Array(points[offset...]) + Array(points[..<offset])
            if meaningfulChoiceCount(in: rotated) > 0 { return rotated }
        }
        return points
    }

    static func stableSeed(for value: String) -> Int {
        value.unicodeScalars.reduce(17) { result, scalar in
            (result * 31 + Int(scalar.value)) % 100_003
        }
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}

/// Curated partial-picture strokes model the useful visual anchors found on good paper
/// dot-to-dots: faces, windows, texture and interior structure are already present, while the
/// numbered trail alone owns the exterior. These are bespoke vectors, not emoji artwork.
enum DotPuzzleArtwork {
    static func preDrawnDetails(for id: String) -> [[CGPoint]] {
        switch id {
        case "rocket":
            return [oval(0.50, 0.34, 0.09, 0.10), [p(0.34, 0.58), p(0.66, 0.58)]]
        case "star":
            return friendlyFace(eyeY: 0.43, mouthY: 0.55, spread: 0.11)
        case "fish":
            return [oval(0.32, 0.43, 0.025, 0.025), [p(0.39, 0.37), p(0.43, 0.50), p(0.39, 0.63)],
                    [p(0.55, 0.49), p(0.67, 0.38), p(0.66, 0.61), p(0.55, 0.49)]]
        case "house":
            return [box(0.27, 0.49, 0.15, 0.14), box(0.58, 0.49, 0.15, 0.14),
                    [p(0.20, 0.44), p(0.80, 0.44)]]
        case "sailboat":
            return [[p(0.49, 0.17), p(0.49, 0.70)], [p(0.49, 0.23), p(0.76, 0.62)],
                    [p(0.23, 0.80), p(0.78, 0.80)]]
        case "flower":
            return [oval(0.50, 0.46, 0.10, 0.10), [p(0.50, 0.56), p(0.50, 0.91)],
                    [p(0.49, 0.72), p(0.36, 0.64)], [p(0.51, 0.78), p(0.64, 0.69)]]
        case "kite":
            return [[p(0.50, 0.06), p(0.50, 0.70)], [p(0.16, 0.38), p(0.84, 0.38)],
                    [p(0.50, 0.70), p(0.45, 0.80), p(0.55, 0.86), p(0.48, 0.94)]]
        case "heart":
            return [[p(0.25, 0.31), p(0.31, 0.24), p(0.38, 0.25)]]
        case "moon":
            return [oval(0.34, 0.39, 0.05, 0.04), oval(0.31, 0.61, 0.035, 0.035),
                    oval(0.43, 0.74, 0.025, 0.025)]
        case "ice-cream":
            return [[p(0.27, 0.43), p(0.37, 0.39), p(0.48, 0.44), p(0.60, 0.39), p(0.73, 0.43)],
                    [p(0.32, 0.53), p(0.60, 0.82)], [p(0.68, 0.53), p(0.40, 0.82)],
                    [p(0.39, 0.25), p(0.42, 0.25)], [p(0.58, 0.25), p(0.61, 0.25)],
                    [p(0.43, 0.32), p(0.50, 0.35), p(0.57, 0.32)]]
        case "cat":
            return friendlyFace(eyeY: 0.42, mouthY: 0.56, spread: 0.12) + [
                [p(0.48, 0.50), p(0.50, 0.53), p(0.52, 0.50), p(0.48, 0.50)],
                [p(0.43, 0.54), p(0.25, 0.50)], [p(0.43, 0.58), p(0.24, 0.62)],
                [p(0.57, 0.54), p(0.75, 0.50)], [p(0.57, 0.58), p(0.76, 0.62)]
            ]
        case "dog":
            return friendlyFace(eyeY: 0.41, mouthY: 0.61, spread: 0.12) + [
                oval(0.50, 0.52, 0.055, 0.04), [p(0.46, 0.67), p(0.50, 0.72), p(0.54, 0.67)]
            ]
        case "butterfly":
            return [oval(0.50, 0.48, 0.045, 0.25), [p(0.48, 0.23), p(0.40, 0.10)],
                    [p(0.52, 0.23), p(0.60, 0.10)], oval(0.27, 0.37, 0.07, 0.09),
                    oval(0.73, 0.37, 0.07, 0.09), oval(0.28, 0.67, 0.05, 0.07),
                    oval(0.72, 0.67, 0.05, 0.07)]
        case "turtle":
            return [oval(0.50, 0.44, 0.27, 0.22), [p(0.31, 0.30), p(0.50, 0.44), p(0.69, 0.30)],
                    [p(0.31, 0.58), p(0.50, 0.44), p(0.69, 0.58)], oval(0.88, 0.47, 0.02, 0.02)]
        case "rabbit":
            return [oval(0.38, 0.43, 0.025, 0.025), [p(0.45, 0.51), p(0.49, 0.54), p(0.44, 0.57)],
                    [p(0.55, 0.68), p(0.70, 0.67), p(0.77, 0.75)]]
        case "duck":
            return [oval(0.39, 0.26, 0.025, 0.025), [p(0.20, 0.40), p(0.34, 0.42)],
                    [p(0.47, 0.55), p(0.61, 0.47), p(0.72, 0.59), p(0.58, 0.68), p(0.47, 0.55)]]
        case "snail":
            return [spiral(0.45, 0.44, 0.20), [p(0.75, 0.50), p(0.83, 0.31)],
                    [p(0.84, 0.53), p(0.91, 0.36)], oval(0.83, 0.29, 0.018, 0.018), oval(0.91, 0.34, 0.018, 0.018)]
        case "crown":
            return [[p(0.18, 0.69), p(0.82, 0.69)], oval(0.36, 0.56, 0.035, 0.045),
                    oval(0.50, 0.56, 0.035, 0.045), oval(0.64, 0.56, 0.035, 0.045)]
        case "dolphin":
            return [oval(0.69, 0.39, 0.022, 0.022), [p(0.69, 0.46), p(0.77, 0.48)],
                    [p(0.48, 0.56), p(0.58, 0.70), p(0.62, 0.54)]]
        case "penguin":
            return [oval(0.50, 0.57, 0.22, 0.30)] + friendlyFace(eyeY: 0.30, mouthY: 0.39, spread: 0.08) + [
                [p(0.46, 0.38), p(0.50, 0.43), p(0.54, 0.38)]
            ]
        case "dinosaur":
            return [[p(0.40, 0.54), p(0.54, 0.55), p(0.66, 0.48)]]
        case "whale":
            return [oval(0.28, 0.48, 0.025, 0.025), [p(0.22, 0.58), p(0.38, 0.62)],
                    [p(0.52, 0.60), p(0.62, 0.72), p(0.68, 0.57)],
                    [p(0.43, 0.19), p(0.40, 0.09)], [p(0.47, 0.19), p(0.53, 0.08)]]
        case "elephant":
            return [oval(0.67, 0.38, 0.025, 0.025), oval(0.50, 0.42, 0.16, 0.20),
                    [p(0.86, 0.43), p(0.80, 0.58), p(0.85, 0.69)]]
        case "giraffe":
            return [oval(0.61, 0.22, 0.022, 0.022), oval(0.46, 0.48, 0.04, 0.055),
                    oval(0.53, 0.64, 0.045, 0.06), oval(0.39, 0.72, 0.04, 0.055)]
        case "lion":
            return [oval(0.50, 0.50, 0.25, 0.27)] + friendlyFace(eyeY: 0.44, mouthY: 0.60, spread: 0.10) + [
                oval(0.50, 0.54, 0.055, 0.045)
            ]
        case "crab":
            return [oval(0.39, 0.40, 0.025, 0.025), oval(0.61, 0.40, 0.025, 0.025),
                    [p(0.41, 0.53), p(0.50, 0.58), p(0.59, 0.53)]]
        case "airplane":
            return [oval(0.50, 0.22, 0.035, 0.05), [p(0.44, 0.42), p(0.56, 0.42)],
                    [p(0.44, 0.52), p(0.56, 0.52)]]
        case "octopus":
            return friendlyFace(eyeY: 0.38, mouthY: 0.52, spread: 0.11) + [
                oval(0.30, 0.70, 0.018, 0.018), oval(0.50, 0.78, 0.018, 0.018), oval(0.70, 0.70, 0.018, 0.018)
            ]
        case "shark":
            return [oval(0.71, 0.42, 0.024, 0.024), [p(0.67, 0.51), p(0.75, 0.53)],
                    [p(0.62, 0.45), p(0.59, 0.53)], [p(0.72, 0.54), p(0.75, 0.58), p(0.78, 0.54)]]
        case "robot":
            return [box(0.33, 0.25, 0.34, 0.25), oval(0.41, 0.35, 0.025, 0.025),
                    oval(0.59, 0.35, 0.025, 0.025), [p(0.42, 0.43), p(0.58, 0.43)],
                    box(0.38, 0.55, 0.24, 0.13)]
        case "sun":
            return friendlyFace(eyeY: 0.44, mouthY: 0.57, spread: 0.11)
        case "cloud":
            return friendlyFace(eyeY: 0.52, mouthY: 0.63, spread: 0.11)
        case "tree":
            return [[p(0.43, 0.78), p(0.57, 0.78)], [p(0.50, 0.25), p(0.50, 0.72)],
                    [p(0.50, 0.43), p(0.34, 0.34)], [p(0.50, 0.57), p(0.68, 0.47)]]
        case "apple":
            return [[p(0.50, 0.21), p(0.49, 0.10)], [p(0.52, 0.15), p(0.66, 0.11), p(0.61, 0.20)],
                    [p(0.29, 0.34), p(0.25, 0.48)]]
        case "pear":
            return [[p(0.48, 0.20), p(0.51, 0.08)], [p(0.51, 0.12), p(0.64, 0.09), p(0.59, 0.18)],
                    [p(0.29, 0.51), p(0.25, 0.62)]]
        case "strawberry":
            return [[p(0.31, 0.22), p(0.50, 0.30), p(0.69, 0.22)],
                    oval(0.36, 0.46, 0.018, 0.03), oval(0.57, 0.43, 0.018, 0.03),
                    oval(0.47, 0.61, 0.018, 0.03), oval(0.60, 0.70, 0.018, 0.03)]
        case "watermelon":
            return [[p(0.13, 0.59), p(0.87, 0.59)], oval(0.37, 0.39, 0.018, 0.035),
                    oval(0.50, 0.31, 0.018, 0.035), oval(0.63, 0.42, 0.018, 0.035)]
        case "cupcake":
            return [[p(0.23, 0.41), p(0.34, 0.37), p(0.45, 0.42), p(0.57, 0.37), p(0.76, 0.41)],
                    [p(0.37, 0.46), p(0.41, 0.84)], [p(0.50, 0.45), p(0.50, 0.87)],
                    [p(0.63, 0.46), p(0.59, 0.84)]]
        case "pizza":
            return [[p(0.15, 0.74), p(0.50, 0.83), p(0.85, 0.74)],
                    oval(0.43, 0.46, 0.045, 0.045), oval(0.61, 0.62, 0.045, 0.045), oval(0.35, 0.69, 0.035, 0.035)]
        case "umbrella":
            return [[p(0.50, 0.09), p(0.22, 0.42)], [p(0.50, 0.09), p(0.50, 0.44)],
                    [p(0.50, 0.09), p(0.76, 0.42)]]
        case "balloon":
            return [[p(0.36, 0.23), p(0.31, 0.39)], [p(0.50, 0.82), p(0.43, 0.92), p(0.55, 1.00)]]
        case "present":
            return [[p(0.50, 0.36), p(0.50, 0.91)], [p(0.16, 0.58), p(0.84, 0.58)]]
        case "bell":
            return [oval(0.50, 0.84, 0.055, 0.055), [p(0.35, 0.31), p(0.31, 0.54)]]
        case "key":
            return [oval(0.27, 0.28, 0.09, 0.09), [p(0.42, 0.48), p(0.76, 0.75)]]
        case "snowman":
            return friendlyFace(eyeY: 0.24, mouthY: 0.34, spread: 0.07) + [
                [p(0.47, 0.29), p(0.58, 0.31)], [p(0.29, 0.43), p(0.71, 0.43)],
                oval(0.50, 0.59, 0.022, 0.022), oval(0.50, 0.72, 0.022, 0.022),
                [p(0.23, 0.58), p(0.06, 0.48)], [p(0.77, 0.58), p(0.94, 0.48)]
            ]
        case "mountain":
            return [[p(0.39, 0.58), p(0.55, 0.13), p(0.67, 0.49)], [p(0.25, 0.64), p(0.37, 0.50)]]
        case "rainbow":
            return [arc(0.50, 0.83, 0.34, 0.55), arc(0.50, 0.83, 0.25, 0.40)]
        case "castle":
            return [box(0.18, 0.40, 0.13, 0.17), box(0.69, 0.40, 0.13, 0.17),
                    [p(0.47, 0.18), p(0.47, 0.06), p(0.62, 0.11), p(0.47, 0.14)]]
        case "lighthouse":
            return [[p(0.38, 0.51), p(0.62, 0.51)], [p(0.35, 0.69), p(0.65, 0.69)],
                    box(0.45, 0.22, 0.10, 0.10), [p(0.31, 0.28), p(0.08, 0.18)], [p(0.69, 0.28), p(0.92, 0.18)]]
        case "anchor":
            return [oval(0.50, 0.18, 0.075, 0.075), [p(0.30, 0.48), p(0.70, 0.48)],
                    [p(0.50, 0.27), p(0.50, 0.78)]]
        case "shell":
            return [[p(0.50, 0.91), p(0.29, 0.33)], [p(0.50, 0.91), p(0.40, 0.20)],
                    [p(0.50, 0.91), p(0.60, 0.20)], [p(0.50, 0.91), p(0.71, 0.33)]]
        case "music-note":
            return [[p(0.40, 0.28), p(0.82, 0.16)]]
        case "book":
            return [[p(0.50, 0.24), p(0.50, 0.88)], [p(0.18, 0.34), p(0.39, 0.39)],
                    [p(0.61, 0.39), p(0.82, 0.34)], [p(0.18, 0.51), p(0.39, 0.56)], [p(0.61, 0.56), p(0.82, 0.51)]]
        case "pencil":
            return [[p(0.18, 0.77), p(0.30, 0.89)], [p(0.69, 0.12), p(0.86, 0.28)],
                    [p(0.23, 0.56), p(0.43, 0.74)]]
        case "fox":
            return friendlyFace(eyeY: 0.43, mouthY: 0.61, spread: 0.11) + [
                [p(0.31, 0.34), p(0.50, 0.50), p(0.69, 0.34)], [p(0.47, 0.53), p(0.50, 0.57), p(0.53, 0.53)]
            ]
        case "bear", "teddy":
            return friendlyFace(eyeY: 0.43, mouthY: 0.61, spread: 0.11) + [oval(0.50, 0.55, 0.075, 0.06)]
        case "panda":
            return [oval(0.38, 0.43, 0.08, 0.055), oval(0.62, 0.43, 0.08, 0.055),
                    oval(0.38, 0.43, 0.022, 0.022), oval(0.62, 0.43, 0.022, 0.022), oval(0.50, 0.55, 0.055, 0.04)]
        case "koala":
            return friendlyFace(eyeY: 0.42, mouthY: 0.63, spread: 0.11) + [oval(0.50, 0.54, 0.07, 0.10)]
        case "monkey":
            return [oval(0.50, 0.55, 0.22, 0.22)] + friendlyFace(eyeY: 0.42, mouthY: 0.63, spread: 0.10)
        case "frog":
            return [oval(0.27, 0.20, 0.04, 0.04), oval(0.73, 0.20, 0.04, 0.04),
                    [p(0.34, 0.55), p(0.50, 0.62), p(0.66, 0.55)]]
        case "owl":
            return [oval(0.37, 0.43, 0.11, 0.13), oval(0.63, 0.43, 0.11, 0.13),
                    oval(0.37, 0.43, 0.025, 0.025), oval(0.63, 0.43, 0.025, 0.025),
                    [p(0.46, 0.54), p(0.50, 0.62), p(0.54, 0.54), p(0.46, 0.54)]]
        case "chicken":
            return [oval(0.53, 0.29, 0.025, 0.025), [p(0.62, 0.36), p(0.73, 0.41), p(0.62, 0.46)],
                    [p(0.40, 0.54), p(0.56, 0.47), p(0.67, 0.61), p(0.48, 0.68), p(0.40, 0.54)]]
        case "pig":
            return friendlyFace(eyeY: 0.42, mouthY: 0.65, spread: 0.11) + [oval(0.50, 0.56, 0.11, 0.075),
                    oval(0.46, 0.56, 0.017, 0.025), oval(0.54, 0.56, 0.017, 0.025)]
        case "cow":
            return friendlyFace(eyeY: 0.40, mouthY: 0.68, spread: 0.11) + [oval(0.50, 0.59, 0.16, 0.11),
                    oval(0.44, 0.59, 0.018, 0.025), oval(0.56, 0.59, 0.018, 0.025), oval(0.35, 0.31, 0.06, 0.05)]
        case "sheep":
            return [oval(0.50, 0.52, 0.18, 0.24)] + friendlyFace(eyeY: 0.44, mouthY: 0.63, spread: 0.08)
        case "horse":
            return [oval(0.61, 0.42, 0.025, 0.025), oval(0.70, 0.61, 0.018, 0.025),
                    [p(0.31, 0.27), p(0.38, 0.40), p(0.35, 0.59)]]
        case "zebra":
            return [oval(0.82, 0.46, 0.022, 0.022), [p(0.34, 0.32), p(0.41, 0.59)],
                    [p(0.47, 0.31), p(0.50, 0.60)], [p(0.60, 0.31), p(0.58, 0.59)], [p(0.73, 0.33), p(0.68, 0.54)]]
        case "camel":
            return [oval(0.84, 0.43, 0.022, 0.022), [p(0.36, 0.53), p(0.62, 0.53)],
                    [p(0.36, 0.54), p(0.42, 0.66), p(0.58, 0.66), p(0.64, 0.54)]]
        case "crocodile":
            return [oval(0.82, 0.47, 0.022, 0.022), [p(0.69, 0.57), p(0.90, 0.58)],
                    [p(0.72, 0.58), p(0.75, 0.63), p(0.78, 0.58), p(0.81, 0.63), p(0.84, 0.58)]]
        case "seahorse":
            return [oval(0.62, 0.19, 0.022, 0.022), [p(0.48, 0.41), p(0.34, 0.49), p(0.48, 0.57)],
                    [p(0.50, 0.63), p(0.61, 0.70)]]
        case "jellyfish":
            return friendlyFace(eyeY: 0.34, mouthY: 0.46, spread: 0.10) + [
                [p(0.35, 0.52), p(0.32, 0.75)], [p(0.50, 0.52), p(0.50, 0.78)], [p(0.65, 0.52), p(0.68, 0.75)]
            ]
        case "bee":
            return [oval(0.40, 0.42, 0.022, 0.022), oval(0.60, 0.42, 0.022, 0.022),
                    [p(0.27, 0.51), p(0.73, 0.51)], [p(0.31, 0.62), p(0.69, 0.62)]]
        case "ladybird":
            return [[p(0.50, 0.21), p(0.50, 0.92)], oval(0.35, 0.46, 0.045, 0.045),
                    oval(0.66, 0.46, 0.045, 0.045), oval(0.38, 0.68, 0.045, 0.045), oval(0.62, 0.68, 0.045, 0.045)]
        case "spider":
            return [oval(0.50, 0.36, 0.11, 0.12), oval(0.50, 0.58, 0.15, 0.18),
                    oval(0.46, 0.32, 0.018, 0.018), oval(0.54, 0.32, 0.018, 0.018)]
        case "mouse":
            return friendlyFace(eyeY: 0.43, mouthY: 0.60, spread: 0.11) + [oval(0.50, 0.53, 0.04, 0.035),
                    [p(0.43, 0.55), p(0.24, 0.50)], [p(0.43, 0.60), p(0.23, 0.65)],
                    [p(0.57, 0.55), p(0.76, 0.50)], [p(0.57, 0.60), p(0.77, 0.65)]]
        case "squirrel":
            return [oval(0.73, 0.40, 0.022, 0.022), [p(0.18, 0.28), p(0.36, 0.34), p(0.30, 0.64), p(0.14, 0.68)],
                    [p(0.61, 0.63), p(0.72, 0.69), p(0.78, 0.64)]]
        case "hedgehog":
            return [oval(0.79, 0.52, 0.022, 0.022), [p(0.24, 0.39), p(0.31, 0.56), p(0.24, 0.67)],
                    [p(0.38, 0.30), p(0.43, 0.52)], [p(0.52, 0.27), p(0.55, 0.50)], [p(0.66, 0.34), p(0.65, 0.53)]]
        case "car":
            return [box(0.34, 0.32, 0.31, 0.22), oval(0.28, 0.76, 0.075, 0.075), oval(0.70, 0.76, 0.075, 0.075)]
        case "bus":
            return [box(0.20, 0.23, 0.18, 0.22), box(0.42, 0.23, 0.18, 0.22), box(0.64, 0.23, 0.16, 0.22),
                    oval(0.30, 0.82, 0.07, 0.07), oval(0.70, 0.82, 0.07, 0.07)]
        case "train":
            return [box(0.38, 0.28, 0.15, 0.17), oval(0.25, 0.80, 0.07, 0.07),
                    oval(0.69, 0.80, 0.07, 0.07), [p(0.15, 0.57), p(0.84, 0.57)]]
        case "saturn":
            return [[p(0.06, 0.38), p(0.32, 0.48), p(0.50, 0.52), p(0.68, 0.48), p(0.94, 0.38)],
                    [p(0.07, 0.43), p(0.31, 0.56), p(0.50, 0.60), p(0.69, 0.56), p(0.93, 0.43)],
                    oval(0.46, 0.31, 0.045, 0.032), oval(0.58, 0.70, 0.035, 0.025)]
        case "tractor":
            return [box(0.42, 0.25, 0.23, 0.24), oval(0.28, 0.76, 0.13, 0.13), oval(0.73, 0.77, 0.08, 0.08)]
        case "fire-engine":
            return [box(0.38, 0.31, 0.24, 0.21), oval(0.27, 0.78, 0.075, 0.075), oval(0.72, 0.78, 0.075, 0.075),
                    [p(0.19, 0.35), p(0.65, 0.15)], [p(0.26, 0.39), p(0.69, 0.20)]]
        case "submarine":
            return [oval(0.32, 0.57, 0.05, 0.05), oval(0.50, 0.57, 0.05, 0.05), oval(0.68, 0.57, 0.05, 0.05),
                    [p(0.50, 0.22), p(0.50, 0.12), p(0.61, 0.12)]]
        case "helicopter":
            return [box(0.34, 0.37, 0.24, 0.21), [p(0.45, 0.30), p(0.45, 0.17)], [p(0.21, 0.17), p(0.72, 0.17)],
                    [p(0.30, 0.73), p(0.70, 0.73)], [p(0.34, 0.67), p(0.30, 0.73)], [p(0.66, 0.67), p(0.70, 0.73)]]
        case "hot-air-balloon":
            return [[p(0.50, 0.08), p(0.50, 0.74)], [p(0.35, 0.15), p(0.42, 0.74)], [p(0.65, 0.15), p(0.58, 0.74)],
                    [p(0.43, 0.76), p(0.42, 0.87)], [p(0.57, 0.76), p(0.58, 0.87)]]
        case "guitar":
            return [oval(0.35, 0.66, 0.08, 0.08), [p(0.36, 0.66), p(0.78, 0.19)],
                    [p(0.40, 0.69), p(0.82, 0.22)], [p(0.26, 0.50), p(0.48, 0.76)]]
        case "drum":
            return [[p(0.16, 0.34), p(0.84, 0.34)], [p(0.20, 0.76), p(0.80, 0.76)],
                    [p(0.24, 0.38), p(0.70, 0.76)], [p(0.76, 0.38), p(0.30, 0.76)],
                    [p(0.34, 0.18), p(0.56, 0.05)], [p(0.66, 0.18), p(0.44, 0.05)]]
        case "camera":
            return [oval(0.50, 0.57, 0.18, 0.18), oval(0.50, 0.57, 0.09, 0.09),
                    box(0.72, 0.37, 0.10, 0.08), oval(0.24, 0.39, 0.025, 0.025)]
        case "football":
            return [closed([p(0.50, 0.34), p(0.63, 0.44), p(0.58, 0.59), p(0.42, 0.59), p(0.37, 0.44)]),
                    [p(0.50, 0.34), p(0.50, 0.14)], [p(0.63, 0.44), p(0.82, 0.35)],
                    [p(0.58, 0.59), p(0.69, 0.78)], [p(0.42, 0.59), p(0.31, 0.78)], [p(0.37, 0.44), p(0.18, 0.35)]]
        case "treasure-map":
            return [[p(0.27, 0.33), p(0.38, 0.41), p(0.47, 0.36), p(0.58, 0.51), p(0.69, 0.46)],
                    [p(0.65, 0.38), p(0.73, 0.46)], [p(0.73, 0.38), p(0.65, 0.46)],
                    oval(0.31, 0.67, 0.10, 0.10), [p(0.31, 0.54), p(0.31, 0.80)], [p(0.18, 0.67), p(0.44, 0.67)]]
        case "mermaid":
            return [oval(0.50, 0.19, 0.08, 0.10), [p(0.38, 0.30), p(0.50, 0.42), p(0.62, 0.30)],
                    [p(0.39, 0.45), p(0.50, 0.50), p(0.61, 0.45)],
                    [p(0.44, 0.58), p(0.56, 0.58)], [p(0.44, 0.66), p(0.56, 0.66)], [p(0.46, 0.74), p(0.54, 0.74)]]
        case "dragon":
            return [oval(0.80, 0.42, 0.022, 0.022),
                    [p(0.46, 0.42), p(0.62, 0.29), p(0.66, 0.54), p(0.46, 0.42)],
                    [p(0.18, 0.61), p(0.08, 0.52), p(0.02, 0.61)], oval(0.57, 0.62, 0.025, 0.025)]
        case "unicorn":
            return [oval(0.80, 0.34, 0.022, 0.022), [p(0.70, 0.27), p(0.84, 0.07)],
                    [p(0.66, 0.28), p(0.56, 0.39), p(0.59, 0.57)],
                    [p(0.26, 0.41), p(0.15, 0.35), p(0.08, 0.47)],
                    [p(0.44, 0.42), p(0.54, 0.47), p(0.44, 0.52)]]
        case "pirate-ship":
            return [[p(0.49, 0.17), p(0.49, 0.70)], [p(0.49, 0.24), p(0.76, 0.39), p(0.49, 0.55), p(0.49, 0.24)],
                    [p(0.24, 0.78), p(0.79, 0.78)], [p(0.49, 0.18), p(0.65, 0.10), p(0.65, 0.22), p(0.49, 0.18)]]
        case "treasure-chest":
            return [[p(0.11, 0.50), p(0.89, 0.50)], [p(0.29, 0.13), p(0.29, 0.88)],
                    [p(0.71, 0.13), p(0.71, 0.88)], box(0.45, 0.55, 0.10, 0.14)]
        case "excavator":
            return [box(0.43, 0.29, 0.19, 0.20), oval(0.46, 0.79, 0.21, 0.10),
                    [p(0.69, 0.48), p(0.83, 0.27), p(0.91, 0.23)], [p(0.21, 0.76), p(0.71, 0.76)]]
        case "volcano":
            return [[p(0.41, 0.31), p(0.50, 0.36), p(0.59, 0.31)],
                    [p(0.50, 0.36), p(0.44, 0.56), p(0.52, 0.67), p(0.47, 0.83)],
                    [p(0.43, 0.20), p(0.36, 0.12), p(0.40, 0.05)], [p(0.57, 0.20), p(0.65, 0.10), p(0.61, 0.04)]]
        default:
            return []
        }
    }

    static func finishingDetails(for id: String) -> [[CGPoint]] {
        switch id {
        case "dinosaur":
            return [oval(0.58, 0.46, 0.025, 0.025)]
        case "astronaut":
            return [oval(0.50, 0.26, 0.12, 0.04)]
        case "mermaid":
            return [[p(0.42, 0.33), p(0.50, 0.38), p(0.58, 0.33)],
                    [p(0.43, 0.51), p(0.50, 0.55), p(0.57, 0.51)]]
        case "dragon":
            return [[p(0.54, 0.58), p(0.59, 0.63), p(0.64, 0.58)]]
        case "unicorn":
            return [[p(0.58, 0.35), p(0.50, 0.29), p(0.46, 0.39)],
                    [p(0.18, 0.45), p(0.10, 0.55), p(0.22, 0.58)]]
        default:
            return []
        }
    }

    private static func friendlyFace(
        eyeY: CGFloat,
        mouthY: CGFloat,
        spread: CGFloat
    ) -> [[CGPoint]] {
        [
            oval(0.50 - spread, eyeY, 0.022, 0.026),
            oval(0.50 + spread, eyeY, 0.022, 0.026),
            [p(0.42, mouthY), p(0.50, mouthY + 0.05), p(0.58, mouthY)]
        ]
    }

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
        closed([p(x, y), p(x + width, y), p(x + width, y + height), p(x, y + height)])
    }

    private static func arc(
        _ centerX: CGFloat,
        _ baselineY: CGFloat,
        _ radiusX: CGFloat,
        _ radiusY: CGFloat,
        steps: Int = 14
    ) -> [CGPoint] {
        (0...steps).map { index in
            let angle = CGFloat.pi + CGFloat(index) / CGFloat(steps) * CGFloat.pi
            return p(centerX + cos(angle) * radiusX, baselineY + sin(angle) * radiusY)
        }
    }

    private static func spiral(_ centerX: CGFloat, _ centerY: CGFloat, _ radius: CGFloat) -> [CGPoint] {
        (0...22).map { index in
            let fraction = CGFloat(index) / 22
            let angle = fraction * CGFloat.pi * 4.5
            let currentRadius = radius * (1 - fraction * 0.82)
            return p(centerX + cos(angle) * currentRadius, centerY + sin(angle) * currentRadius)
        }
    }

    private static func closed(_ points: [CGPoint]) -> [CGPoint] {
        guard let first = points.first else { return [] }
        return points + [first]
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct DotPaintSwatch: Identifiable {
    let id: Int
    let color: Color
}

enum DotPaintingPlan {
    static func regionCount(for puzzle: DotPuzzle) -> Int {
        switch puzzle.tier {
        case .firstDots: return 3
        case .numberTrail, .numberExplorer: return 4
        case .bigNumberAdventure: return 5
        }
    }

    static func swatches(for puzzle: DotPuzzle) -> [DotPaintSwatch] {
        let colors: [Color] = [
            Color(hex: "fbbf24"), Color(hex: "2dd4bf"), Color(hex: "fb7185"),
            Color(hex: "c084fc"), Color(hex: "38bdf8")
        ]
        let count = regionCount(for: puzzle)
        let rotation = DotPuzzleGeometry.stableSeed(for: puzzle.id) % colors.count
        return (0..<count).map { index in
            DotPaintSwatch(id: index + 1, color: colors[(index + rotation) % colors.count])
        }
    }

    static func region(at point: CGPoint, for puzzle: DotPuzzle) -> Int? {
        guard contains(point, polygon: puzzle.revealOutline) else { return nil }
        let bounds = xBounds(for: puzzle)
        guard bounds.width > 0 else { return 1 }
        let fraction = min(max((point.x - bounds.minX) / bounds.width, 0), 0.999_999)
        return min(Int(fraction * CGFloat(regionCount(for: puzzle))) + 1, regionCount(for: puzzle))
    }

    static func xRange(for region: Int, puzzle: DotPuzzle) -> ClosedRange<CGFloat> {
        let bounds = xBounds(for: puzzle)
        let count = CGFloat(regionCount(for: puzzle))
        let lower = bounds.minX + bounds.width * CGFloat(region - 1) / count
        let upper = bounds.minX + bounds.width * CGFloat(region) / count
        return lower...upper
    }

    /// Finds a legible label position inside each clipped colour region, including narrow shapes.
    static func labelPoint(for region: Int, puzzle: DotPuzzle) -> CGPoint {
        let xRange = xRange(for: region, puzzle: puzzle)
        let preferredX = (xRange.lowerBound + xRange.upperBound) / 2
        let candidatesY: [CGFloat] = [0.50, 0.42, 0.58, 0.34, 0.66, 0.26, 0.74, 0.18, 0.82]
        let candidatesX: [CGFloat] = [preferredX, xRange.lowerBound * 0.35 + xRange.upperBound * 0.65,
                                      xRange.lowerBound * 0.65 + xRange.upperBound * 0.35]
        for y in candidatesY {
            for x in candidatesX {
                let candidate = CGPoint(x: x, y: y)
                if contains(candidate, polygon: puzzle.revealOutline) { return candidate }
            }
        }

        // Narrow and concave pictures (a music note is the canonical case) may not contain any of
        // the aesthetically preferred anchors above. Search the actual region at a finer cadence
        // before falling back, keeping every printed paint numeral inside the revealed artwork.
        for yStep in 1..<30 {
            let y = CGFloat(yStep) / 30
            for xStep in 1..<20 {
                let fraction = CGFloat(xStep) / 20
                let x = xRange.lowerBound + (xRange.upperBound - xRange.lowerBound) * fraction
                let candidate = CGPoint(x: x, y: y)
                if Self.region(at: candidate, for: puzzle) == region { return candidate }
            }
        }
        return CGPoint(x: preferredX, y: 0.50)
    }

    private static func xBounds(for puzzle: DotPuzzle) -> (minX: CGFloat, width: CGFloat) {
        let values = puzzle.revealOutline.map(\.x)
        let minimum = values.min() ?? 0
        return (minimum, (values.max() ?? 1) - minimum)
    }

    private static func contains(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var previous = polygon.count - 1
        for current in polygon.indices {
            let a = polygon[current]
            let b = polygon[previous]
            let crosses = ((a.y > point.y) != (b.y > point.y))
                && point.x < (b.x - a.x) * (point.y - a.y) / ((b.y - a.y) == 0 ? 0.000_001 : (b.y - a.y)) + a.x
            if crosses { inside.toggle() }
            previous = current
        }
        return inside
    }
}

enum SubitizingChallenge {
    static func quantity(for puzzleID: String) -> Int {
        let value = puzzleID.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return value % 5 + 1
    }

    static func choices(for quantity: Int, puzzleID: String) -> [Int] {
        let rawChoices = [
            quantity,
            quantity % 5 + 1,
            (quantity + 2) % 5 + 1
        ]
        let rotation = puzzleID.count % rawChoices.count
        return Array(rawChoices[rotation...] + rawChoices[..<rotation])
    }

    static func pattern(for quantity: Int) -> [CGPoint] {
        switch quantity {
        case 1:
            return [CGPoint(x: 0.50, y: 0.50)]
        case 2:
            return [CGPoint(x: 0.30, y: 0.30), CGPoint(x: 0.70, y: 0.70)]
        case 3:
            return [
                CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.50, y: 0.50),
                CGPoint(x: 0.72, y: 0.72)
            ]
        case 4:
            return [
                CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.72, y: 0.28),
                CGPoint(x: 0.28, y: 0.72), CGPoint(x: 0.72, y: 0.72)
            ]
        default:
            return [
                CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.25, y: 0.75),
                CGPoint(x: 0.75, y: 0.75)
            ]
        }
    }
}
