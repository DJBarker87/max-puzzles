import Foundation

// MARK: - Expression

/// A generated arithmetic expression
struct Expression {
    let text: String
    let operation: Operation
    let operandA: Int
    let operandB: Int
    let result: Int
}

// MARK: - ExpressionGenerator

/// Generates arithmetic expressions for puzzle cells
enum ExpressionGenerator {

    // MARK: - Operation Selection

    /// Select a random operation based on weights
    static func selectOperation(weights: OperationWeights, settings: DifficultySettings) -> Operation {
        var enabledWeights: [(op: Operation, weight: Int)] = []

        if settings.additionEnabled && weights.addition > 0 {
            enabledWeights.append((.addition, weights.addition))
        }
        if settings.subtractionEnabled && weights.subtraction > 0 {
            enabledWeights.append((.subtraction, weights.subtraction))
        }
        if settings.multiplicationEnabled && weights.multiplication > 0 {
            enabledWeights.append((.multiplication, weights.multiplication))
        }
        if settings.divisionEnabled && weights.division > 0 {
            enabledWeights.append((.division, weights.division))
        }

        guard !enabledWeights.isEmpty else {
            return .addition // Fallback
        }

        let total = enabledWeights.reduce(0) { $0 + $1.weight }
        var random = Int.random(in: 0..<total)

        for (op, weight) in enabledWeights {
            random -= weight
            if random < 0 {
                return op
            }
        }

        return enabledWeights[0].op
    }

    // MARK: - Individual Operation Generators

    /// Generate addition: a + b = target
    static func generateAddition(target: Int, maxOperand: Int) -> Expression? {
        guard target >= 2 else { return nil }

        // For a + b = target where both a, b in [1, maxOperand]:
        // a must satisfy: max(1, target - maxOperand) <= a <= min(maxOperand, target - 1)
        let minA = max(1, target - maxOperand)
        let maxA = min(maxOperand, target - 1)

        guard minA <= maxA else { return nil }

        let a = Int.random(in: minA...maxA)
        let b = target - a

        return Expression(
            text: "\(a) + \(b)",
            operation: .addition,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    /// Generate subtraction: a - b = target (where a > b, no negatives)
    static func generateSubtraction(target: Int, maxOperand: Int) -> Expression? {
        guard target >= 1 else { return nil }

        // a - b = target, so a = target + b
        // b can be 1 to (maxOperand - target)
        let maxB = maxOperand - target
        guard maxB >= 1 else { return nil }

        let b = Int.random(in: 1...maxB)
        let a = target + b

        // Ensure a is within reasonable range
        guard a <= maxOperand * 2 else { return nil }

        return Expression(
            text: "\(a) − \(b)",  // Unicode minus
            operation: .subtraction,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    /// Generate multiplication: a × b = target
    static func generateMultiplication(target: Int, maxFactor: Int) -> Expression? {
        guard target >= 4 else { return nil } // Need at least 2 × 2

        // Find all valid factor pairs
        var pairs: [(Int, Int)] = []
        let sqrtTarget = Int(sqrt(Double(target)))
        let upperBound = min(maxFactor, sqrtTarget)

        // Guard against invalid range
        guard upperBound >= 2 else { return nil }

        for a in 2...upperBound {
            if target % a == 0 {
                let b = target / a
                if b >= 2 && b <= maxFactor {
                    pairs.append((a, b))
                }
            }
        }

        guard let (a, b) = pairs.randomElement() else { return nil }

        // Randomly swap order
        if Bool.random() {
            return Expression(
                text: "\(a) × \(b)",
                operation: .multiplication,
                operandA: a,
                operandB: b,
                result: target
            )
        } else {
            return Expression(
                text: "\(b) × \(a)",
                operation: .multiplication,
                operandA: b,
                operandB: a,
                result: target
            )
        }
    }

    /// Generate division: a ÷ b = target (where a = target × b)
    static func generateDivision(target: Int, maxDivisor: Int, maxDividend: Int = 1000) -> Expression? {
        guard target >= 1 else { return nil }

        // a ÷ b = target, so a = target × b
        let maxB = min(maxDivisor, 12)
        var validDivisors: [Int] = []

        for b in 2...maxB {
            let a = target * b
            if a <= maxDividend {
                validDivisors.append(b)
            }
        }

        guard let b = validDivisors.randomElement() else { return nil }
        let a = target * b

        return Expression(
            text: "\(a) ÷ \(b)",
            operation: .division,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    // MARK: - Multiplication Boost

    /// Check if a number is a good multiplication candidate
    /// Returns likelihood boost (0 to 1)
    private static func getMultiplicationBoost(target: Int, maxFactor: Int) -> Double {
        // Check if this number has valid factor pairs (factors >= 2)
        var hasValidFactors = false
        let sqrtTarget = Int(sqrt(Double(target)))
        let upperBound = min(maxFactor, sqrtTarget)

        // Guard against invalid range (target < 4 means sqrtTarget < 2)
        guard upperBound >= 2 else { return 0 }

        for a in 2...upperBound {
            if target % a == 0 {
                let b = target / a
                if b >= 2 && b <= maxFactor {
                    hasValidFactors = true
                    break
                }
            }
        }

        guard hasValidFactors else { return 0 }

        // Scale likelihood based on value
        if target <= 25 {
            return 0.40
        } else if target >= 50 {
            return 0.60
        } else {
            // Linear interpolation
            return 0.40 + Double(target - 25) * 0.008
        }
    }

    // MARK: - Main Expression Generator

    /// Generate an arithmetic expression that evaluates to the target value
    static func generateExpression(
        target: Int,
        difficulty: DifficultySettings,
        prioritizeDivision: Bool = false
    ) -> Expression {
        let maxDivisionAnswer = difficulty.multDivRange

        // Try up to 10 times
        for _ in 0..<10 {
            var operation: Operation

            // Division priority for marked cells
            if prioritizeDivision && difficulty.divisionEnabled && target <= maxDivisionAnswer {
                if Double.random(in: 0...1) < 0.8 {
                    operation = .division
                } else {
                    operation = selectOperation(weights: difficulty.weights, settings: difficulty)
                }
            } else if difficulty.multiplicationEnabled && !prioritizeDivision {
                // Check for multiplication boost
                let multBoost = getMultiplicationBoost(target: target, maxFactor: difficulty.multDivRange)
                if multBoost > 0 && Double.random(in: 0...1) < multBoost {
                    operation = .multiplication
                } else {
                    operation = selectOperation(weights: difficulty.weights, settings: difficulty)
                }
            } else {
                operation = selectOperation(weights: difficulty.weights, settings: difficulty)
            }

            var expression: Expression?

            switch operation {
            case .addition:
                expression = generateAddition(target: target, maxOperand: difficulty.addSubRange)
            case .subtraction:
                expression = generateSubtraction(target: target, maxOperand: difficulty.addSubRange)
            case .multiplication:
                expression = generateMultiplication(target: target, maxFactor: difficulty.multDivRange)
            case .division:
                if target <= maxDivisionAnswer {
                    expression = generateDivision(target: target, maxDivisor: difficulty.multDivRange)
                }
            }

            if let expr = expression {
                return expr
            }
        }

        // Fallback: handle edge cases
        if target == 1 {
            return Expression(
                text: "2 − 1",
                operation: .subtraction,
                operandA: 2,
                operandB: 1,
                result: 1
            )
        }

        // Force addition with relaxed constraints
        let a = target / 2
        let b = target - a
        return Expression(
            text: "\(a) + \(b)",
            operation: .addition,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    // MARK: - Apply Expressions to Cells

    /// Apply expressions to all cells in the grid (mutates cells)
    static func applyExpressions(
        cells: inout [[Cell]],
        difficulty: DifficultySettings,
        divisionCells: Set<String> = []
    ) {
        for row in 0..<cells.count {
            for col in 0..<cells[row].count {
                var cell = cells[row][col]

                if cell.isFinish {
                    // FINISH cell doesn't need an expression
                    cell.expression = ""
                } else if let answer = cell.answer {
                    // Generate math expression
                    let prioritizeDivision = divisionCells.contains(cell.coordinate.key)
                    let expression = generateExpression(target: answer, difficulty: difficulty, prioritizeDivision: prioritizeDivision)
                    cell.expression = expression.text
                } else {
                    cell.expression = ""
                }

                cells[row][col] = cell
            }
        }
    }

    // MARK: - Expression Evaluation

    /// Evaluate a simple arithmetic expression
    /// Returns nil for invalid expressions
    static func evaluateExpression(_ expression: String) -> Int? {
        // Handle special cases
        if expression == "START" || expression == "FINISH" || expression.isEmpty {
            return nil
        }

        // Replace unicode operators
        let normalized = expression
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .trimmingCharacters(in: .whitespaces)

        // Parse: "number operator number"
        let pattern = #"^(\d+)\s*([+\-*/])\s*(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              match.numberOfRanges == 4 else {
            return nil
        }

        guard let aRange = Range(match.range(at: 1), in: normalized),
              let opRange = Range(match.range(at: 2), in: normalized),
              let bRange = Range(match.range(at: 3), in: normalized),
              let a = Int(normalized[aRange]),
              let b = Int(normalized[bRange]) else {
            return nil
        }

        let op = String(normalized[opRange])

        switch op {
        case "+": return a + b
        case "-": return a - b
        case "*": return a * b
        case "/": return b != 0 ? a / b : nil
        default: return nil
        }
    }
}
