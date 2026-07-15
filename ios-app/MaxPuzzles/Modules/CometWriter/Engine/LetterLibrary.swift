import Foundation

/// Configurable, unjoined lowercase print and number formations.
///
/// Coordinates are independent from the rendered font and device. This is intentionally data-led:
/// a school's preferred formation can replace these paths without changing validation or UI code.
enum LetterLibrary {
    private static func p(_ x: CGFloat, _ y: CGFloat) -> LetterPoint {
        LetterPoint(x: x, y: y)
    }

    private static func stroke(
        _ coordinates: [(CGFloat, CGFloat)],
        style: LetterStrokeStyle = .smooth
    ) -> LetterStroke {
        LetterStroke(points: coordinates.map { p($0.0, $0.1) }, style: style)
    }

    private static func dot(_ x: CGFloat, _ y: CGFloat) -> LetterStroke {
        LetterStroke(points: [p(x, y)], isDot: true)
    }

    private static func circularStroke(
        centerX: CGFloat,
        centerY: CGFloat,
        radius: CGFloat,
        startDegrees: CGFloat,
        sweepDegrees: CGFloat
    ) -> LetterStroke {
        let stepCount = max(1, Int(ceil(abs(sweepDegrees) / 4)))
        let points = (0...stepCount).map { step -> LetterPoint in
            let amount = CGFloat(step) / CGFloat(stepCount)
            let angle = (startDegrees + sweepDegrees * amount) * .pi / 180
            return p(
                centerX + radius * cos(angle),
                centerY + radius * sin(angle)
            )
        }

        return LetterStroke(points: points, style: .circular)
    }

    private static func ellipticalStroke(
        centerX: CGFloat,
        centerY: CGFloat,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        startDegrees: CGFloat,
        sweepDegrees: CGFloat
    ) -> LetterStroke {
        let stepCount = max(1, Int(ceil(abs(sweepDegrees) / 8)))
        let points = (0...stepCount).map { step -> LetterPoint in
            let amount = CGFloat(step) / CGFloat(stepCount)
            let angle = (startDegrees + sweepDegrees * amount) * .pi / 180
            return p(
                centerX + horizontalRadius * cos(angle),
                centerY + verticalRadius * sin(angle)
            )
        }

        return LetterStroke(points: points)
    }

    static let lowercaseAndNumberOrder = "coagqdiltkjvwuyfrnmhpbesxz0123456789".map(String.init)

    static let lowercaseAndNumbers: [LetterGlyph] = [
        // Magic C: begin near the body's top-right and travel anticlockwise.
        LetterGlyph(character: "c", exampleWord: "cat", family: .magicC, strokes: [
            circularStroke(
                centerX: 0.46,
                centerY: 0.58,
                radius: 0.25,
                startDegrees: -35,
                sweepDegrees: -290
            )
        ]),
        LetterGlyph(character: "o", exampleWord: "octopus", family: .magicC, strokes: [
            circularStroke(
                centerX: 0.46,
                centerY: 0.58,
                radius: 0.25,
                startDegrees: -35,
                sweepDegrees: -360
            )
        ]),
        LetterGlyph(character: "a", exampleWord: "apple", family: .magicC, strokes: [
            stroke([(0.68, 0.43), (0.58, 0.35), (0.42, 0.33), (0.28, 0.39), (0.20, 0.52), (0.21, 0.68), (0.30, 0.79), (0.45, 0.82), (0.59, 0.77), (0.67, 0.65), (0.68, 0.43), (0.68, 0.60), (0.68, 0.82)])
        ]),
        LetterGlyph(character: "d", exampleWord: "dog", family: .magicC, strokes: [
            stroke([(0.64, 0.43), (0.55, 0.35), (0.40, 0.33), (0.27, 0.40), (0.20, 0.54), (0.22, 0.69), (0.32, 0.79), (0.47, 0.82), (0.59, 0.75), (0.65, 0.62), (0.65, 0.43), (0.65, 0.24), (0.65, 0.08), (0.65, 0.32), (0.65, 0.57), (0.65, 0.82)])
        ]),
        LetterGlyph(character: "g", exampleWord: "goat", family: .magicC, strokes: [
            stroke([(0.67, 0.43), (0.57, 0.35), (0.41, 0.33), (0.27, 0.40), (0.20, 0.54), (0.22, 0.69), (0.32, 0.79), (0.47, 0.82), (0.59, 0.75), (0.66, 0.62), (0.67, 0.43), (0.67, 0.68), (0.67, 0.92), (0.61, 1.02), (0.49, 1.04), (0.37, 1.00), (0.32, 0.95)])
        ]),
        LetterGlyph(character: "q", exampleWord: "queen", family: .magicC, strokes: [
            stroke([(0.66, 0.43), (0.56, 0.35), (0.40, 0.33), (0.27, 0.40), (0.20, 0.54), (0.22, 0.69), (0.32, 0.79), (0.47, 0.82), (0.59, 0.75), (0.66, 0.62), (0.66, 0.43), (0.66, 0.70), (0.66, 1.04), (0.77, 0.96)])
        ]),
        LetterGlyph(character: "e", exampleWord: "egg", family: .specials, strokes: [
            stroke([(0.23, 0.58), (0.39, 0.58), (0.58, 0.58), (0.68, 0.52), (0.64, 0.41), (0.52, 0.34), (0.38, 0.35), (0.26, 0.43), (0.20, 0.56), (0.23, 0.70), (0.34, 0.79), (0.49, 0.82), (0.63, 0.77), (0.71, 0.69)])
        ]),
        LetterGlyph(character: "s", exampleWord: "sun", family: .specials, strokes: [
            stroke([(0.68, 0.42), (0.58, 0.35), (0.43, 0.33), (0.29, 0.39), (0.25, 0.49), (0.34, 0.57), (0.49, 0.61), (0.62, 0.67), (0.64, 0.75), (0.55, 0.82), (0.40, 0.83), (0.27, 0.78), (0.21, 0.72)])
        ]),
        LetterGlyph(character: "f", exampleWord: "fish", family: .scoops, strokes: [
            stroke([(0.68, 0.15), (0.60, 0.08), (0.49, 0.09), (0.42, 0.20), (0.40, 0.39), (0.40, 0.62), (0.40, 0.84), (0.40, 1.04)]),
            stroke([(0.24, 0.43), (0.40, 0.43), (0.61, 0.43)], style: .angular)
        ]),

        // Downstrokes: strong top-to-bottom movements, with dots/crossbars added last.
        LetterGlyph(character: "l", exampleWord: "lion", family: .downstrokes, strokes: [
            stroke([(0.46, 0.08), (0.46, 0.28), (0.46, 0.52), (0.46, 0.74), (0.50, 0.82), (0.59, 0.80)])
        ]),
        LetterGlyph(character: "i", exampleWord: "insect", family: .downstrokes, strokes: [
            stroke([(0.48, 0.36), (0.48, 0.55), (0.48, 0.75), (0.52, 0.82), (0.59, 0.80)]),
            dot(0.48, 0.20)
        ]),
        LetterGlyph(character: "t", exampleWord: "tent", family: .downstrokes, strokes: [
            stroke([(0.46, 0.18), (0.46, 0.39), (0.46, 0.62), (0.47, 0.78), (0.54, 0.82), (0.63, 0.77)]),
            stroke([(0.28, 0.40), (0.45, 0.40), (0.64, 0.40)], style: .angular)
        ]),
        LetterGlyph(character: "u", exampleWord: "umbrella", family: .scoops, strokes: [
            stroke([(0.28, 0.36), (0.28, 0.57), (0.29, 0.72), (0.36, 0.80), (0.47, 0.82), (0.57, 0.76), (0.64, 0.64), (0.64, 0.37), (0.64, 0.60), (0.64, 0.82)])
        ]),
        LetterGlyph(character: "j", exampleWord: "jam", family: .downstrokes, strokes: [
            stroke([(0.55, 0.36), (0.55, 0.58), (0.55, 0.82), (0.53, 0.97), (0.44, 1.04), (0.33, 0.98)]),
            dot(0.55, 0.20)
        ]),
        LetterGlyph(character: "y", exampleWord: "yak", family: .scoops, strokes: [
            stroke([(0.32, 0.36), (0.32, 0.57), (0.34, 0.71), (0.39, 0.79), (0.46, 0.82), (0.52, 0.79), (0.57, 0.71), (0.59, 0.58), (0.59, 0.36), (0.59, 0.64), (0.59, 0.84), (0.56, 0.97), (0.49, 1.04), (0.40, 1.06), (0.31, 1.02), (0.27, 0.98)])
        ]),

        // Bumps: down, retrace upward, then travel over a shoulder or bowl.
        LetterGlyph(character: "r", exampleWord: "rocket", family: .bumps, strokes: [
            stroke([(0.31, 0.36), (0.31, 0.58), (0.31, 0.82), (0.31, 0.58), (0.31, 0.39), (0.40, 0.35), (0.51, 0.37), (0.60, 0.45)])
        ]),
        LetterGlyph(character: "n", exampleWord: "nest", family: .bumps, strokes: [
            stroke([(0.27, 0.36), (0.27, 0.58), (0.27, 0.82), (0.27, 0.58), (0.27, 0.39), (0.36, 0.34), (0.48, 0.35), (0.58, 0.44), (0.61, 0.58), (0.61, 0.82)])
        ]),
        LetterGlyph(character: "m", exampleWord: "moon", family: .bumps, strokes: [
            stroke([(0.18, 0.36), (0.18, 0.59), (0.18, 0.82), (0.18, 0.58), (0.18, 0.40), (0.27, 0.35), (0.37, 0.37), (0.44, 0.47), (0.45, 0.82), (0.45, 0.56), (0.46, 0.41), (0.55, 0.35), (0.65, 0.38), (0.72, 0.49), (0.72, 0.82)])
        ]),
        LetterGlyph(character: "h", exampleWord: "hat", family: .bumps, strokes: [
            stroke([(0.29, 0.08), (0.29, 0.31), (0.29, 0.58), (0.29, 0.82), (0.29, 0.59), (0.29, 0.42), (0.38, 0.35), (0.50, 0.36), (0.59, 0.46), (0.61, 0.61), (0.61, 0.82)])
        ]),
        LetterGlyph(character: "b", exampleWord: "ball", family: .bumps, strokes: [
            stroke([(0.30, 0.08), (0.30, 0.32), (0.30, 0.57), (0.30, 0.82), (0.30, 0.61), (0.31, 0.43), (0.42, 0.35), (0.55, 0.36), (0.65, 0.45), (0.69, 0.59), (0.65, 0.72), (0.55, 0.80), (0.42, 0.82), (0.30, 0.82)])
        ]),
        LetterGlyph(character: "p", exampleWord: "pig", family: .bumps, strokes: [
            stroke([(0.30, 0.36), (0.30, 0.60), (0.30, 0.82), (0.30, 1.04), (0.30, 0.77), (0.30, 0.53), (0.31, 0.41), (0.42, 0.35), (0.55, 0.37), (0.65, 0.47), (0.68, 0.60), (0.62, 0.73), (0.51, 0.80), (0.39, 0.82), (0.30, 0.82)])
        ]),
        LetterGlyph(character: "k", exampleWord: "kite", family: .downstrokes, strokes: [
            stroke([(0.30, 0.08), (0.30, 0.33), (0.30, 0.58), (0.30, 0.82)], style: .angular),
            stroke([(0.66, 0.35), (0.53, 0.47), (0.39, 0.59), (0.52, 0.69), (0.68, 0.82)], style: .angular)
        ]),

        // Scoops and slants: diagonal or under-and-up movements.
        LetterGlyph(character: "v", exampleWord: "van", family: .scoops, strokes: [
            stroke([(0.24, 0.36), (0.31, 0.58), (0.42, 0.82), (0.53, 0.60), (0.64, 0.36)], style: .angular)
        ]),
        LetterGlyph(character: "w", exampleWord: "web", family: .scoops, strokes: [
            stroke([(0.14, 0.36), (0.20, 0.59), (0.29, 0.82), (0.39, 0.61), (0.47, 0.82), (0.57, 0.61), (0.66, 0.36)], style: .angular)
        ]),
        LetterGlyph(character: "x", exampleWord: "x-ray", family: .specials, strokes: [
            stroke([(0.28, 0.36), (0.42, 0.58), (0.59, 0.82)], style: .angular),
            stroke([(0.60, 0.36), (0.45, 0.58), (0.28, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "z", exampleWord: "zebra", family: .specials, strokes: [
            stroke([(0.25, 0.36), (0.46, 0.36), (0.66, 0.36), (0.52, 0.53), (0.38, 0.69), (0.25, 0.82), (0.47, 0.82), (0.68, 0.82)], style: .angular)
        ]),

        // Number Nebula: school-style print numerals with explicit starts and stroke order.
        LetterGlyph(character: "0", exampleWord: "zero", family: .numbers, strokes: [
            ellipticalStroke(
                centerX: 0.46,
                centerY: 0.45,
                horizontalRadius: 0.22,
                verticalRadius: 0.36,
                startDegrees: -90,
                sweepDegrees: -360
            )
        ]),
        LetterGlyph(character: "1", exampleWord: "one", family: .numbers, strokes: [
            stroke([(0.46, 0.08), (0.46, 0.31), (0.46, 0.57), (0.46, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "2", exampleWord: "two", family: .numbers, strokes: [
            stroke([(0.25, 0.25), (0.29, 0.14), (0.40, 0.08), (0.54, 0.10), (0.64, 0.20), (0.64, 0.32), (0.56, 0.44), (0.43, 0.56), (0.31, 0.68), (0.23, 0.82), (0.44, 0.82), (0.68, 0.82)])
        ]),
        LetterGlyph(character: "3", exampleWord: "three", family: .numbers, strokes: [
            stroke([(0.27, 0.16), (0.39, 0.08), (0.54, 0.10), (0.64, 0.20), (0.62, 0.33), (0.49, 0.43), (0.61, 0.48), (0.67, 0.61), (0.63, 0.75), (0.52, 0.82), (0.37, 0.82), (0.25, 0.74)])
        ]),
        LetterGlyph(character: "4", exampleWord: "four", family: .numbers, strokes: [
            stroke([(0.59, 0.08), (0.48, 0.26), (0.37, 0.43), (0.27, 0.58), (0.47, 0.58), (0.68, 0.58)], style: .angular),
            stroke([(0.59, 0.08), (0.59, 0.33), (0.59, 0.58), (0.59, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "5", exampleWord: "five", family: .numbers, strokes: [
            stroke([(0.30, 0.09), (0.29, 0.25), (0.28, 0.41), (0.40, 0.37), (0.54, 0.39), (0.64, 0.49), (0.66, 0.63), (0.59, 0.76), (0.46, 0.83), (0.32, 0.80), (0.23, 0.72)]),
            stroke([(0.30, 0.09), (0.48, 0.09), (0.66, 0.09)], style: .angular)
        ]),
        LetterGlyph(character: "6", exampleWord: "six", family: .numbers, strokes: [
            stroke([(0.63, 0.14), (0.54, 0.08), (0.42, 0.12), (0.32, 0.24), (0.25, 0.42), (0.23, 0.60), (0.29, 0.75), (0.42, 0.83), (0.55, 0.79), (0.64, 0.67), (0.64, 0.54), (0.57, 0.44), (0.44, 0.40), (0.32, 0.45), (0.24, 0.57)])
        ]),
        LetterGlyph(character: "7", exampleWord: "seven", family: .numbers, strokes: [
            stroke([(0.24, 0.09), (0.46, 0.09), (0.68, 0.09), (0.58, 0.29), (0.48, 0.48), (0.38, 0.66), (0.31, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "8", exampleWord: "eight", family: .numbers, strokes: [
            stroke([(0.46, 0.08), (0.33, 0.11), (0.27, 0.23), (0.30, 0.35), (0.46, 0.45), (0.61, 0.55), (0.65, 0.69), (0.59, 0.80), (0.46, 0.84), (0.32, 0.80), (0.26, 0.68), (0.30, 0.55), (0.46, 0.45), (0.61, 0.35), (0.65, 0.22), (0.59, 0.11), (0.46, 0.08)])
        ]),
        LetterGlyph(character: "9", exampleWord: "nine", family: .numbers, strokes: [
            stroke([(0.62, 0.25), (0.56, 0.13), (0.43, 0.09), (0.30, 0.15), (0.24, 0.28), (0.26, 0.42), (0.36, 0.51), (0.49, 0.52), (0.60, 0.45), (0.63, 0.31), (0.62, 0.25), (0.62, 0.48), (0.61, 0.66), (0.58, 0.82)])
        ])
    ]

    /// Explicit UK-style print capitals. Each lift is a separate stroke so start, direction and
    /// order can be taught and validated rather than inferred from a display font.
    static let uppercase: [LetterGlyph] = [
        LetterGlyph(character: "A", exampleWord: "apple", family: .capitals, strokes: [
            stroke([(0.46, 0.08), (0.32, 0.44), (0.18, 0.82)], style: .angular),
            stroke([(0.46, 0.08), (0.60, 0.44), (0.74, 0.82)], style: .angular),
            stroke([(0.31, 0.55), (0.46, 0.55), (0.61, 0.55)], style: .angular)
        ]),
        LetterGlyph(character: "B", exampleWord: "ball", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.45), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.48, 0.08), (0.67, 0.16), (0.70, 0.29), (0.62, 0.41), (0.45, 0.45), (0.25, 0.45)]),
            stroke([(0.25, 0.45), (0.49, 0.45), (0.69, 0.54), (0.72, 0.68), (0.62, 0.79), (0.45, 0.82), (0.25, 0.82)])
        ]),
        LetterGlyph(character: "C", exampleWord: "cat", family: .capitals, strokes: [
            stroke([(0.70, 0.18), (0.58, 0.09), (0.42, 0.08), (0.27, 0.16), (0.19, 0.32), (0.18, 0.53), (0.26, 0.70), (0.41, 0.82), (0.57, 0.81), (0.70, 0.72)])
        ]),
        LetterGlyph(character: "D", exampleWord: "dog", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.45), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.46, 0.08), (0.64, 0.18), (0.73, 0.36), (0.73, 0.54), (0.64, 0.72), (0.46, 0.82), (0.25, 0.82)])
        ]),
        LetterGlyph(character: "E", exampleWord: "egg", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.45), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.72, 0.08)], style: .angular),
            stroke([(0.25, 0.45), (0.62, 0.45)], style: .angular),
            stroke([(0.25, 0.82), (0.72, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "F", exampleWord: "fish", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.45), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.72, 0.08)], style: .angular),
            stroke([(0.25, 0.45), (0.62, 0.45)], style: .angular)
        ]),
        LetterGlyph(character: "G", exampleWord: "goat", family: .capitals, strokes: [
            stroke([(0.70, 0.18), (0.58, 0.09), (0.42, 0.08), (0.27, 0.16), (0.19, 0.32), (0.18, 0.53), (0.26, 0.70), (0.41, 0.82), (0.58, 0.80), (0.70, 0.70)]),
            stroke([(0.70, 0.55), (0.60, 0.55), (0.50, 0.55)], style: .angular)
        ]),
        LetterGlyph(character: "H", exampleWord: "hat", family: .capitals, strokes: [
            stroke([(0.24, 0.08), (0.24, 0.82)], style: .angular),
            stroke([(0.72, 0.08), (0.72, 0.82)], style: .angular),
            stroke([(0.24, 0.45), (0.72, 0.45)], style: .angular)
        ]),
        LetterGlyph(character: "I", exampleWord: "insect", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.71, 0.08)], style: .angular),
            stroke([(0.48, 0.08), (0.48, 0.82)], style: .angular),
            stroke([(0.25, 0.82), (0.71, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "J", exampleWord: "jam", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.72, 0.08)], style: .angular),
            stroke([(0.62, 0.08), (0.62, 0.52), (0.59, 0.69), (0.49, 0.80), (0.35, 0.81), (0.25, 0.70)])
        ]),
        LetterGlyph(character: "K", exampleWord: "kite", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.82)], style: .angular),
            stroke([(0.72, 0.08), (0.48, 0.28), (0.25, 0.45)], style: .angular),
            stroke([(0.25, 0.45), (0.48, 0.62), (0.72, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "L", exampleWord: "lion", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.82), (0.72, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "M", exampleWord: "moon", family: .capitals, strokes: [
            stroke([(0.18, 0.08), (0.18, 0.82)], style: .angular),
            stroke([(0.18, 0.08), (0.47, 0.53), (0.76, 0.08)], style: .angular),
            stroke([(0.76, 0.08), (0.76, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "N", exampleWord: "nest", family: .capitals, strokes: [
            stroke([(0.22, 0.08), (0.22, 0.82)], style: .angular),
            stroke([(0.22, 0.82), (0.72, 0.08)], style: .angular),
            stroke([(0.72, 0.08), (0.72, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "O", exampleWord: "octopus", family: .capitals, strokes: [
            ellipticalStroke(centerX: 0.48, centerY: 0.45, horizontalRadius: 0.26, verticalRadius: 0.37, startDegrees: -90, sweepDegrees: -360)
        ]),
        LetterGlyph(character: "P", exampleWord: "pig", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.48, 0.08), (0.67, 0.16), (0.70, 0.29), (0.62, 0.42), (0.45, 0.48), (0.25, 0.48)])
        ]),
        LetterGlyph(character: "Q", exampleWord: "queen", family: .capitals, strokes: [
            ellipticalStroke(centerX: 0.48, centerY: 0.45, horizontalRadius: 0.26, verticalRadius: 0.37, startDegrees: -90, sweepDegrees: -360),
            stroke([(0.52, 0.62), (0.63, 0.75), (0.74, 0.88)], style: .angular)
        ]),
        LetterGlyph(character: "R", exampleWord: "rocket", family: .capitals, strokes: [
            stroke([(0.25, 0.08), (0.25, 0.82)], style: .angular),
            stroke([(0.25, 0.08), (0.48, 0.08), (0.67, 0.16), (0.70, 0.29), (0.62, 0.41), (0.45, 0.46), (0.25, 0.46)]),
            stroke([(0.25, 0.46), (0.48, 0.62), (0.72, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "S", exampleWord: "sun", family: .capitals, strokes: [
            stroke([(0.68, 0.18), (0.57, 0.09), (0.41, 0.08), (0.27, 0.16), (0.24, 0.30), (0.34, 0.41), (0.53, 0.48), (0.66, 0.58), (0.65, 0.71), (0.54, 0.80), (0.38, 0.82), (0.25, 0.72)])
        ]),
        LetterGlyph(character: "T", exampleWord: "tent", family: .capitals, strokes: [
            stroke([(0.18, 0.08), (0.76, 0.08)], style: .angular),
            stroke([(0.47, 0.08), (0.47, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "U", exampleWord: "umbrella", family: .capitals, strokes: [
            stroke([(0.22, 0.08), (0.22, 0.55), (0.26, 0.70), (0.37, 0.81), (0.51, 0.82), (0.64, 0.74), (0.72, 0.58), (0.72, 0.08)])
        ]),
        LetterGlyph(character: "V", exampleWord: "van", family: .capitals, strokes: [
            stroke([(0.18, 0.08), (0.47, 0.82), (0.76, 0.08)], style: .angular)
        ]),
        LetterGlyph(character: "W", exampleWord: "web", family: .capitals, strokes: [
            stroke([(0.12, 0.08), (0.28, 0.82), (0.47, 0.42), (0.64, 0.82), (0.82, 0.08)], style: .angular)
        ]),
        LetterGlyph(character: "X", exampleWord: "x-ray", family: .capitals, strokes: [
            stroke([(0.22, 0.08), (0.72, 0.82)], style: .angular),
            stroke([(0.72, 0.08), (0.22, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "Y", exampleWord: "yak", family: .capitals, strokes: [
            stroke([(0.18, 0.08), (0.47, 0.45)], style: .angular),
            stroke([(0.76, 0.08), (0.47, 0.45)], style: .angular),
            stroke([(0.47, 0.45), (0.47, 0.82)], style: .angular)
        ]),
        LetterGlyph(character: "Z", exampleWord: "zebra", family: .capitals, strokes: [
            stroke([(0.20, 0.08), (0.74, 0.08), (0.20, 0.82), (0.74, 0.82)], style: .angular)
        ])
    ]

    static let practiceOrder = lowercaseAndNumberOrder + LetterFormationStandard.uppercaseOrder
    static let all = lowercaseAndNumbers + uppercase

    static func glyph(for character: String) -> LetterGlyph? {
        all.first { $0.character == character }
            ?? all.first { $0.character == character.lowercased() }
    }

    static func glyphs(in family: LetterFamily) -> [LetterGlyph] {
        let familyGlyphs = all.filter { $0.family == family }
        return practiceOrder.compactMap { id in familyGlyphs.first { $0.character == id } }
    }

    static func next(after glyph: LetterGlyph) -> LetterGlyph? {
        guard let index = practiceOrder.firstIndex(of: glyph.character) else { return nil }
        let nextIndex = practiceOrder.index(after: index)
        guard nextIndex < practiceOrder.endIndex else { return nil }
        return self.glyph(for: practiceOrder[nextIndex])
    }
}
