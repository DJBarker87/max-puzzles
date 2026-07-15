import XCTest
@testable import MaxPuzzles

final class ExpressionGeneratorTests: XCTestCase {

    func testAdditionExpressionEvaluatesCorrectly() {
        for target in [5, 10, 15, 20, 25] {
            if let expr = ExpressionGenerator.generateAddition(target: target, maxOperand: 30) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testSubtractionExpressionEvaluatesCorrectly() {
        for target in [5, 10, 15, 20] {
            if let expr = ExpressionGenerator.generateSubtraction(target: target, maxOperand: 30) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testMultiplicationExpressionEvaluatesCorrectly() {
        for target in [6, 12, 24, 36, 48] {
            if let expr = ExpressionGenerator.generateMultiplication(target: target, maxFactor: 12) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testDivisionExpressionEvaluatesCorrectly() {
        for target in [2, 3, 4, 5, 6] {
            if let expr = ExpressionGenerator.generateDivision(target: target, maxDivisor: 12) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testEvaluateExpressionHandlesUnicode() {
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("10 − 3"), 7)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("4 × 5"), 20)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("20 ÷ 4"), 5)
    }

    func testEvaluateExpressionHandlesASCII() {
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("10 - 3"), 7)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("4 * 5"), 20)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("20 / 4"), 5)
    }

    func testExpressionGeneratorAlwaysReturnsValidExpression() {
        // Use a simpler difficulty with only addition/subtraction
        let difficulty = DifficultyPresets.byLevel(3)

        // Test common target values
        for target in 5...30 {
            let expr = ExpressionGenerator.generateExpression(target: target, difficulty: difficulty)
            XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target, "Expression for target \(target) should evaluate correctly")
        }
    }

    func testAdditionGeneratesValidOperands() {
        for _ in 0..<20 {
            if let expr = ExpressionGenerator.generateAddition(target: 15, maxOperand: 10) {
                XCTAssertGreaterThanOrEqual(expr.operandA, 1)
                XCTAssertLessThanOrEqual(expr.operandA, 10)
                XCTAssertGreaterThanOrEqual(expr.operandB, 1)
                XCTAssertLessThanOrEqual(expr.operandB, 10)
                XCTAssertEqual(expr.operandA + expr.operandB, 15)
            }
        }
    }

    func testSubtractionNoNegatives() {
        for _ in 0..<20 {
            if let expr = ExpressionGenerator.generateSubtraction(target: 5, maxOperand: 20) {
                XCTAssertGreaterThan(expr.operandA, expr.operandB)
                XCTAssertGreaterThanOrEqual(expr.operandB, 1)
                XCTAssertEqual(expr.operandA - expr.operandB, 5)
            }
        }
    }

    func testMultiplicationUsesValidFactors() {
        for _ in 0..<20 {
            if let expr = ExpressionGenerator.generateMultiplication(target: 24, maxFactor: 12) {
                XCTAssertGreaterThanOrEqual(expr.operandA, 2)
                XCTAssertGreaterThanOrEqual(expr.operandB, 2)
                XCTAssertLessThanOrEqual(expr.operandA, 12)
                XCTAssertLessThanOrEqual(expr.operandB, 12)
                XCTAssertEqual(expr.operandA * expr.operandB, 24)
            }
        }
    }

    func testMultiplicationUsesOnlySelectedTimesTables() throws {
        for target in stride(from: 7, through: 84, by: 7) {
            let expression = try XCTUnwrap(
                ExpressionGenerator.generateMultiplication(
                    target: target,
                    maxFactor: 12,
                    selectedTables: [7]
                )
            )
            XCTAssertTrue(expression.operandA == 7 || expression.operandB == 7)
            XCTAssertEqual(expression.result, target)
        }

        XCTAssertNil(
            ExpressionGenerator.generateMultiplication(
                target: 20,
                maxFactor: 12,
                selectedTables: [7]
            )
        )
    }

    func testDivisionUsesASelectedTableAsTheDivisor() throws {
        for _ in 0..<20 {
            let expression = try XCTUnwrap(
                ExpressionGenerator.generateDivision(
                    target: 6,
                    maxDivisor: 12,
                    selectedTables: [7, 9]
                )
            )
            XCTAssertTrue([7, 9].contains(expression.operandB))
            XCTAssertEqual(expression.result, 6)
        }
    }

    func testMultiplicationOnlyPuzzleHonoursExactTableSelection() throws {
        let settings = DifficultySettings(
            name: "Exact 7s",
            additionEnabled: false,
            subtractionEnabled: false,
            multiplicationEnabled: true,
            divisionEnabled: false,
            addSubRange: 20,
            multDivRange: 12,
            selectedTimesTables: [7],
            connectorMin: 1,
            connectorMax: 84,
            gridRows: 3,
            gridCols: 4,
            minPathLength: 6,
            maxPathLength: 10,
            weights: OperationWeights(multiplication: 100),
            hiddenMode: false,
            secondsPerStep: 7
        )

        let result = PuzzleGenerator.generatePuzzle(difficulty: settings)
        guard case let .success(puzzle) = result else {
            return XCTFail("An exact-table puzzle should generate successfully")
        }

        for cell in puzzle.grid.flatMap({ $0 }) where !cell.expression.isEmpty {
            let operands = cell.expression
                .components(separatedBy: "×")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            XCTAssertEqual(operands.count, 2, "Unexpected expression: \(cell.expression)")
            XCTAssertTrue(operands.contains(7), "Non-7-times-table expression: \(cell.expression)")
        }
    }

    func testDivisionProducesWholeNumber() {
        for _ in 0..<20 {
            if let expr = ExpressionGenerator.generateDivision(target: 5, maxDivisor: 12) {
                XCTAssertGreaterThanOrEqual(expr.operandB, 2)
                XCTAssertEqual(expr.operandA % expr.operandB, 0)
                XCTAssertEqual(expr.operandA / expr.operandB, 5)
            }
        }
    }

    func testEvaluateExpressionReturnsNilForInvalid() {
        XCTAssertNil(ExpressionGenerator.evaluateExpression("START"))
        XCTAssertNil(ExpressionGenerator.evaluateExpression("FINISH"))
        XCTAssertNil(ExpressionGenerator.evaluateExpression(""))
        XCTAssertNil(ExpressionGenerator.evaluateExpression("abc"))
        XCTAssertNil(ExpressionGenerator.evaluateExpression("1 + 2 + 3"))  // Multiple operators
    }

    func testEvaluateExpressionHandlesDivisionByZero() {
        XCTAssertNil(ExpressionGenerator.evaluateExpression("10 / 0"))
        XCTAssertNil(ExpressionGenerator.evaluateExpression("10 ÷ 0"))
    }

    func testSelectOperationRespectsWeights() {
        let settings = DifficultySettings(
            name: "Test",
            additionEnabled: true,
            subtractionEnabled: false,
            multiplicationEnabled: false,
            divisionEnabled: false,
            addSubRange: 10,
            multDivRange: 0,
            connectorMin: 5,
            connectorMax: 10,
            gridRows: 3,
            gridCols: 4,
            minPathLength: 5,
            maxPathLength: 10,
            weights: OperationWeights(addition: 100, subtraction: 0, multiplication: 0, division: 0),
            hiddenMode: false,
            secondsPerStep: 10
        )

        // With only addition enabled, should always return addition
        for _ in 0..<20 {
            let op = ExpressionGenerator.selectOperation(weights: settings.weights, settings: settings)
            XCTAssertEqual(op, .addition)
        }
    }
}
