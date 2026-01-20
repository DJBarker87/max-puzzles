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
