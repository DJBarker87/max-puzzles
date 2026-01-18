import type { Operation, DifficultySettings, OperationWeights } from './types'
import type { Cell } from '../types'
import { randomInt } from './valueAssigner'

/**
 * A generated arithmetic expression
 */
export interface Expression {
  text: string
  operation: Operation
  operandA: number
  operandB: number
  result: number
}

/**
 * Select a random operation based on weights
 */
export function selectOperation(weights: OperationWeights, settings: DifficultySettings): Operation {
  const enabledWeights: { op: Operation; weight: number }[] = []

  if (settings.additionEnabled && weights.addition > 0) {
    enabledWeights.push({ op: '+', weight: weights.addition })
  }
  if (settings.subtractionEnabled && weights.subtraction > 0) {
    enabledWeights.push({ op: '−', weight: weights.subtraction })
  }
  if (settings.multiplicationEnabled && weights.multiplication > 0) {
    enabledWeights.push({ op: '×', weight: weights.multiplication })
  }
  if (settings.divisionEnabled && weights.division > 0) {
    enabledWeights.push({ op: '÷', weight: weights.division })
  }

  if (enabledWeights.length === 0) {
    return '+' // Fallback to addition
  }

  const total = enabledWeights.reduce((sum, w) => sum + w.weight, 0)
  let random = Math.random() * total

  for (const { op, weight } of enabledWeights) {
    random -= weight
    if (random <= 0) {
      return op
    }
  }

  return enabledWeights[0].op
}

/**
 * Generate an addition expression: a + b = target
 * Both a and b must be in range [1, maxOperand]
 */
export function generateAddition(target: number, maxOperand: number): Expression | null {
  if (target < 2) return null

  // For a + b = target where both a, b in [1, maxOperand]:
  // a must satisfy: max(1, target - maxOperand) <= a <= min(maxOperand, target - 1)
  const minA = Math.max(1, target - maxOperand)
  const maxA = Math.min(maxOperand, target - 1)

  if (minA > maxA) return null // No valid range

  const a = randomInt(minA, maxA)
  const b = target - a

  return {
    text: `${a} + ${b}`,
    operation: '+',
    operandA: a,
    operandB: b,
    result: target,
  }
}

/**
 * Generate a subtraction expression: a - b = target (where a > b, no negatives)
 */
export function generateSubtraction(target: number, maxOperand: number): Expression | null {
  if (target < 1) return null

  // a - b = target, so a = target + b
  // b can be 1 to (maxOperand - target)
  const maxB = maxOperand - target
  if (maxB < 1) return null

  const b = randomInt(1, maxB)
  const a = target + b

  // Ensure a is within range
  if (a > maxOperand * 2) return null // Reasonable limit

  return {
    text: `${a} − ${b}`,
    operation: '−',
    operandA: a,
    operandB: b,
    result: target,
  }
}

/**
 * Generate a multiplication expression: a × b = target
 */
export function generateMultiplication(target: number, maxFactor: number): Expression | null {
  if (target < 4) return null // Need at least 2 × 2

  // Find all valid factor pairs
  const pairs: [number, number][] = []
  for (let a = 2; a <= Math.min(maxFactor, Math.sqrt(target)); a++) {
    if (target % a === 0) {
      const b = target / a
      if (b >= 2 && b <= maxFactor) {
        pairs.push([a, b])
      }
    }
  }

  if (pairs.length === 0) return null

  // Pick random pair
  const [a, b] = pairs[Math.floor(Math.random() * pairs.length)]

  // Randomly swap order
  if (Math.random() < 0.5) {
    return {
      text: `${a} × ${b}`,
      operation: '×',
      operandA: a,
      operandB: b,
      result: target,
    }
  } else {
    return {
      text: `${b} × ${a}`,
      operation: '×',
      operandA: b,
      operandB: a,
      result: target,
    }
  }
}

/**
 * Generate a division expression: a ÷ b = target (where a = target × b)
 */
export function generateDivision(
  target: number,
  maxDivisor: number,
  maxDividend: number = 1000
): Expression | null {
  if (target < 1) return null

  // a ÷ b = target, so a = target × b
  // Find valid divisors b where a <= maxDividend
  const validDivisors: number[] = []
  const maxB = Math.min(maxDivisor, 12)

  for (let b = 2; b <= maxB; b++) {
    const a = target * b
    if (a <= maxDividend) {
      validDivisors.push(b)
    }
  }

  if (validDivisors.length === 0) return null

  const b = validDivisors[Math.floor(Math.random() * validDivisors.length)]
  const a = target * b

  return {
    text: `${a} ÷ ${b}`,
    operation: '÷',
    operandA: a,
    operandB: b,
    result: target,
  }
}

/**
 * Generate an arithmetic expression that evaluates to the target value
 */
export function generateExpression(
  target: number,
  difficulty: DifficultySettings
): Expression {
  // Try up to 10 times to generate a valid expression
  for (let attempt = 0; attempt < 10; attempt++) {
    const operation = selectOperation(difficulty.weights, difficulty)

    let expression: Expression | null = null

    switch (operation) {
      case '+':
        expression = generateAddition(target, difficulty.addSubRange)
        break
      case '−':
        expression = generateSubtraction(target, difficulty.addSubRange)
        break
      case '×':
        expression = generateMultiplication(target, difficulty.multDivRange)
        break
      case '÷':
        expression = generateDivision(target, difficulty.multDivRange)
        break
    }

    if (expression) {
      return expression
    }
  }

  // Fallback: always use addition or handle edge case
  if (target === 1) {
    return {
      text: '2 − 1',
      operation: '−',
      operandA: 2,
      operandB: 1,
      result: 1,
    }
  }

  // Force addition with relaxed constraints
  const a = Math.floor(target / 2)
  const b = target - a
  return {
    text: `${a} + ${b}`,
    operation: '+',
    operandA: a,
    operandB: b,
    result: target,
  }
}

/**
 * Apply expressions to all cells in the grid
 * Mutates cells in place
 */
export function applyExpressions(
  cells: Cell[][],
  difficulty: DifficultySettings
): void {
  for (const row of cells) {
    for (const cell of row) {
      if (cell.isFinish) {
        // FINISH cell doesn't need an expression - it shows "FINISH"
        cell.expression = ''
      } else if (cell.answer !== null) {
        // Generate math expression for all cells including START
        const expression = generateExpression(cell.answer, difficulty)
        cell.expression = expression.text
      } else {
        cell.expression = ''
      }
    }
  }
}

/**
 * Evaluate a simple arithmetic expression
 * Handles unicode operators: +, −, ×, ÷
 */
export function evaluateExpression(expression: string): number | null {
  // Handle special cases
  if (expression === 'START' || expression === 'FINISH') {
    return null
  }

  // Replace unicode operators with JS operators
  const jsExpression = expression
    .replace(/−/g, '-')
    .replace(/×/g, '*')
    .replace(/÷/g, '/')

  // Parse simple binary expression: "number operator number"
  const match = jsExpression.match(/^\s*(\d+)\s*([+\-*/])\s*(\d+)\s*$/)
  if (!match) {
    return null
  }

  const a = parseInt(match[1], 10)
  const op = match[2]
  const b = parseInt(match[3], 10)

  switch (op) {
    case '+': return a + b
    case '-': return a - b
    case '*': return a * b
    case '/': return b !== 0 ? a / b : null
    default: return null
  }
}
