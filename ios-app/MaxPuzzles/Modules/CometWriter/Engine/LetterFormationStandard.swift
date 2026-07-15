import Foundation

/// The single teaching standard used by Comet Writer.
///
/// This is UK Reception / Year 1 unjoined print: single-storey `a` and `g`, letters grouped by
/// repeatable movement, dots and crossbars added after the main stroke, and clear ascender /
/// x-height / baseline / descender placement. Keeping the specification separate from the path
/// data lets tests detect a path whose start, finish, stroke count, or line placement drifts.
enum FormationMovementFamily: String, Hashable, Sendable {
    case magicC
    case downstroke
    case scoopAndSlant
    case bump
    case special
    case numeral
    case capital
}

enum FormationHeightClass: String, Hashable, Sendable {
    case xHeight
    case ascender
    case descender
    case ascenderAndDescender
    case numeral
    case capital
}

struct LetterFormationProfile: Hashable, Sendable {
    let movementFamily: FormationMovementFamily
    let heightClass: FormationHeightClass
    let cue: String
    let strokeStarts: [LetterPoint]
    let strokeEnds: [LetterPoint]
}

enum LetterFormationStandard {
    static let lowercaseOrder = "abcdefghijklmnopqrstuvwxyz".map(String.init)
    static let numeralOrder = "0123456789".map(String.init)
    static let uppercaseOrder = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)

    private static func point(_ x: CGFloat, _ y: CGFloat) -> LetterPoint {
        LetterPoint(x: x, y: y)
    }

    private static func profile(
        _ movementFamily: FormationMovementFamily,
        _ heightClass: FormationHeightClass,
        _ cue: String,
        starts: [(CGFloat, CGFloat)],
        ends: [(CGFloat, CGFloat)]
    ) -> LetterFormationProfile {
        precondition(starts.count == ends.count, "Every taught stroke needs a start and finish")
        return LetterFormationProfile(
            movementFamily: movementFamily,
            heightClass: heightClass,
            cue: cue,
            strokeStarts: starts.map { point($0.0, $0.1) },
            strokeEnds: ends.map { point($0.0, $0.1) }
        )
    }

    // Every entry is intentionally explicit. Do not derive one character from another here:
    // reviewers need to be able to audit all 36 formations one by one.
    private static let lowercaseAndNumeralProfiles: [String: LetterFormationProfile] = [
        "a": profile(
            .magicC, .xHeight,
            "Back around, close the round, then straight down.",
            starts: [(0.68, 0.43)], ends: [(0.68, 0.82)]
        ),
        "b": profile(
            .bump, .ascender,
            "Straight down, back up, then round to the line.",
            starts: [(0.30, 0.08)], ends: [(0.30, 0.82)]
        ),
        "c": profile(
            .magicC, .xHeight,
            "Curve back, go round, and stop at the bottom right.",
            starts: [(0.665, 0.437)], ends: [(0.665, 0.723)]
        ),
        "d": profile(
            .magicC, .ascender,
            "Back around, then straight up and down.",
            starts: [(0.64, 0.43)], ends: [(0.65, 0.82)]
        ),
        "e": profile(
            .special, .xHeight,
            "Across the middle, then curve back around.",
            starts: [(0.23, 0.58)], ends: [(0.71, 0.69)]
        ),
        "f": profile(
            .scoopAndSlant, .ascenderAndDescender,
            "Curve back, go straight down below the line; lift and cross.",
            starts: [(0.68, 0.15), (0.24, 0.43)],
            ends: [(0.40, 1.04), (0.61, 0.43)]
        ),
        "g": profile(
            .magicC, .descender,
            "Back around, go below the line, then curl left.",
            starts: [(0.67, 0.43)], ends: [(0.32, 0.95)]
        ),
        "h": profile(
            .bump, .ascender,
            "Down, back up, over the hump, then down.",
            starts: [(0.29, 0.08)], ends: [(0.61, 0.82)]
        ),
        "i": profile(
            .downstroke, .xHeight,
            "Straight down and flick; lift, then add the dot.",
            starts: [(0.48, 0.36), (0.48, 0.20)],
            ends: [(0.59, 0.80), (0.48, 0.20)]
        ),
        "j": profile(
            .downstroke, .descender,
            "Down below the line and curl left; lift and dot.",
            starts: [(0.55, 0.36), (0.55, 0.20)],
            ends: [(0.33, 0.98), (0.55, 0.20)]
        ),
        "k": profile(
            .downstroke, .ascender,
            "Straight down; lift, slant in, then slant out.",
            starts: [(0.30, 0.08), (0.66, 0.35)],
            ends: [(0.30, 0.82), (0.68, 0.82)]
        ),
        "l": profile(
            .downstroke, .ascender,
            "Straight down, then add a small flick right.",
            starts: [(0.46, 0.08)], ends: [(0.59, 0.80)]
        ),
        "m": profile(
            .bump, .xHeight,
            "Down, back up, then over two humps.",
            starts: [(0.18, 0.36)], ends: [(0.72, 0.82)]
        ),
        "n": profile(
            .bump, .xHeight,
            "Down, back up, then over one hump.",
            starts: [(0.27, 0.36)], ends: [(0.61, 0.82)]
        ),
        "o": profile(
            .magicC, .xHeight,
            "Curve back and continue all the way round.",
            starts: [(0.665, 0.437)], ends: [(0.665, 0.437)]
        ),
        "p": profile(
            .bump, .descender,
            "Down below the line, back up, then round.",
            starts: [(0.30, 0.36)], ends: [(0.30, 0.82)]
        ),
        "q": profile(
            .magicC, .descender,
            "Back around, go below the line, then flick right.",
            starts: [(0.66, 0.43)], ends: [(0.77, 0.96)]
        ),
        "r": profile(
            .bump, .xHeight,
            "Down, back up, then over a short shoulder.",
            starts: [(0.31, 0.36)], ends: [(0.60, 0.45)]
        ),
        "s": profile(
            .special, .xHeight,
            "Curve left, then right, finishing near the line.",
            starts: [(0.68, 0.42)], ends: [(0.21, 0.72)]
        ),
        "t": profile(
            .downstroke, .ascender,
            "Straight down and flick; lift, then cross.",
            starts: [(0.46, 0.18), (0.28, 0.40)],
            ends: [(0.63, 0.77), (0.64, 0.40)]
        ),
        "u": profile(
            .scoopAndSlant, .xHeight,
            "Down, scoop round, up, then down to the line.",
            starts: [(0.28, 0.36)], ends: [(0.64, 0.82)]
        ),
        "v": profile(
            .scoopAndSlant, .xHeight,
            "Slant down to the line, then slant back up.",
            starts: [(0.24, 0.36)], ends: [(0.64, 0.36)]
        ),
        "w": profile(
            .scoopAndSlant, .xHeight,
            "Slant down, up, down, and up again.",
            starts: [(0.14, 0.36)], ends: [(0.66, 0.36)]
        ),
        "x": profile(
            .special, .xHeight,
            "Slant down right; lift, then slant down left.",
            starts: [(0.28, 0.36), (0.60, 0.36)],
            ends: [(0.59, 0.82), (0.28, 0.82)]
        ),
        "y": profile(
            .scoopAndSlant, .descender,
            "Down, scoop up, then go well below and curve left.",
            starts: [(0.32, 0.36)], ends: [(0.27, 0.98)]
        ),
        "z": profile(
            .special, .xHeight,
            "Across right, slant back, then across right.",
            starts: [(0.25, 0.36)], ends: [(0.68, 0.82)]
        ),

        "0": profile(
            .numeral, .numeral,
            "Go all the way around and close zero.",
            starts: [(0.46, 0.09)], ends: [(0.46, 0.09)]
        ),
        "1": profile(
            .numeral, .numeral,
            "Go straight down to the line.",
            starts: [(0.46, 0.08)], ends: [(0.46, 0.82)]
        ),
        "2": profile(
            .numeral, .numeral,
            "Curve over, slant down left, then across right.",
            starts: [(0.25, 0.25)], ends: [(0.68, 0.82)]
        ),
        "3": profile(
            .numeral, .numeral,
            "Curve right and back twice.",
            starts: [(0.27, 0.16)], ends: [(0.25, 0.74)]
        ),
        "4": profile(
            .numeral, .numeral,
            "Slant down left and across; lift, then straight down.",
            starts: [(0.59, 0.08), (0.59, 0.08)],
            ends: [(0.68, 0.58), (0.59, 0.82)]
        ),
        "5": profile(
            .numeral, .numeral,
            "Down and curve around; lift, then cross the top.",
            starts: [(0.30, 0.09), (0.30, 0.09)],
            ends: [(0.23, 0.72), (0.66, 0.09)]
        ),
        "6": profile(
            .numeral, .numeral,
            "Curve down and around, then close the lower loop.",
            starts: [(0.63, 0.14)], ends: [(0.24, 0.57)]
        ),
        "7": profile(
            .numeral, .numeral,
            "Across to the right, then slant down to the line.",
            starts: [(0.24, 0.09)], ends: [(0.31, 0.82)]
        ),
        "8": profile(
            .numeral, .numeral,
            "Draw an s, then curve back up to close both loops.",
            starts: [(0.46, 0.08)], ends: [(0.46, 0.08)]
        ),
        "9": profile(
            .numeral, .numeral,
            "Close the loop, then go straight down to the line.",
            starts: [(0.62, 0.25)], ends: [(0.58, 0.82)]
        )
    ]

    private static let uppercaseProfiles: [String: LetterFormationProfile] = [
        "A": profile(.capital, .capital, "Down the left, down the right, then cross.", starts: [(0.46, 0.08), (0.46, 0.08), (0.31, 0.55)], ends: [(0.18, 0.82), (0.74, 0.82), (0.61, 0.55)]),
        "B": profile(.capital, .capital, "Down, then draw the top and bottom bumps.", starts: [(0.25, 0.08), (0.25, 0.08), (0.25, 0.45)], ends: [(0.25, 0.82), (0.25, 0.45), (0.25, 0.82)]),
        "C": profile(.capital, .capital, "Curve back and around, leaving the right open.", starts: [(0.70, 0.18)], ends: [(0.70, 0.72)]),
        "D": profile(.capital, .capital, "Down, then curve from the top back to the bottom.", starts: [(0.25, 0.08), (0.25, 0.08)], ends: [(0.25, 0.82), (0.25, 0.82)]),
        "E": profile(.capital, .capital, "Down, then add top, middle and bottom bars.", starts: [(0.25, 0.08), (0.25, 0.08), (0.25, 0.45), (0.25, 0.82)], ends: [(0.25, 0.82), (0.72, 0.08), (0.62, 0.45), (0.72, 0.82)]),
        "F": profile(.capital, .capital, "Down, then add the top and middle bars.", starts: [(0.25, 0.08), (0.25, 0.08), (0.25, 0.45)], ends: [(0.25, 0.82), (0.72, 0.08), (0.62, 0.45)]),
        "G": profile(.capital, .capital, "Curve around like C, then add the inside bar.", starts: [(0.70, 0.18), (0.70, 0.55)], ends: [(0.70, 0.70), (0.50, 0.55)]),
        "H": profile(.capital, .capital, "Down twice, then cross through the middle.", starts: [(0.24, 0.08), (0.72, 0.08), (0.24, 0.45)], ends: [(0.24, 0.82), (0.72, 0.82), (0.72, 0.45)]),
        "I": profile(.capital, .capital, "Top bar, straight down, then bottom bar.", starts: [(0.25, 0.08), (0.48, 0.08), (0.25, 0.82)], ends: [(0.71, 0.08), (0.48, 0.82), (0.71, 0.82)]),
        "J": profile(.capital, .capital, "Across the top, then down and curve left.", starts: [(0.25, 0.08), (0.62, 0.08)], ends: [(0.72, 0.08), (0.25, 0.70)]),
        "K": profile(.capital, .capital, "Down, slant into the middle, then slant out.", starts: [(0.25, 0.08), (0.72, 0.08), (0.25, 0.45)], ends: [(0.25, 0.82), (0.25, 0.45), (0.72, 0.82)]),
        "L": profile(.capital, .capital, "Straight down, then across the bottom.", starts: [(0.25, 0.08)], ends: [(0.72, 0.82)]),
        "M": profile(.capital, .capital, "Down, make two middle slants, then down.", starts: [(0.18, 0.08), (0.18, 0.08), (0.76, 0.08)], ends: [(0.18, 0.82), (0.76, 0.08), (0.76, 0.82)]),
        "N": profile(.capital, .capital, "Down, slant up across, then down again.", starts: [(0.22, 0.08), (0.22, 0.82), (0.72, 0.08)], ends: [(0.22, 0.82), (0.72, 0.08), (0.72, 0.82)]),
        "O": profile(.capital, .capital, "Start at the top and go all the way around.", starts: [(0.48, 0.08)], ends: [(0.48, 0.08)]),
        "P": profile(.capital, .capital, "Down, then curve around the top bump.", starts: [(0.25, 0.08), (0.25, 0.08)], ends: [(0.25, 0.82), (0.25, 0.48)]),
        "Q": profile(.capital, .capital, "Go around like O, then add a short tail.", starts: [(0.48, 0.08), (0.52, 0.62)], ends: [(0.48, 0.08), (0.74, 0.88)]),
        "R": profile(.capital, .capital, "Down, curve the top bump, then slant a leg.", starts: [(0.25, 0.08), (0.25, 0.08), (0.25, 0.46)], ends: [(0.25, 0.82), (0.25, 0.46), (0.72, 0.82)]),
        "S": profile(.capital, .capital, "Curve left, then right, finishing at the bottom.", starts: [(0.68, 0.18)], ends: [(0.25, 0.72)]),
        "T": profile(.capital, .capital, "Across the top, then straight down the middle.", starts: [(0.18, 0.08), (0.47, 0.08)], ends: [(0.76, 0.08), (0.47, 0.82)]),
        "U": profile(.capital, .capital, "Down, curve around the bottom, then back up.", starts: [(0.22, 0.08)], ends: [(0.72, 0.08)]),
        "V": profile(.capital, .capital, "Slant down to the point, then slant back up.", starts: [(0.18, 0.08)], ends: [(0.76, 0.08)]),
        "W": profile(.capital, .capital, "Slant down, up, down and up again.", starts: [(0.12, 0.08)], ends: [(0.82, 0.08)]),
        "X": profile(.capital, .capital, "Slant down right, then slant down left.", starts: [(0.22, 0.08), (0.72, 0.08)], ends: [(0.72, 0.82), (0.22, 0.82)]),
        "Y": profile(.capital, .capital, "Two slants meet, then go straight down.", starts: [(0.18, 0.08), (0.76, 0.08), (0.47, 0.45)], ends: [(0.47, 0.45), (0.47, 0.45), (0.47, 0.82)]),
        "Z": profile(.capital, .capital, "Across, slant down left, then across again.", starts: [(0.20, 0.08)], ends: [(0.74, 0.82)])
    ]

    static let profiles: [String: LetterFormationProfile] =
        lowercaseAndNumeralProfiles.merging(uppercaseProfiles) { _, uppercase in uppercase }

    static func profile(for character: String) -> LetterFormationProfile? {
        profiles[character] ?? profiles[character.lowercased()]
    }
}

extension LetterGlyph {
    var formationProfile: LetterFormationProfile {
        guard let profile = LetterFormationStandard.profile(for: character) else {
            preconditionFailure("Missing formation standard for \(character)")
        }
        return profile
    }

    var formationCue: String {
        formationProfile.cue
    }
}
