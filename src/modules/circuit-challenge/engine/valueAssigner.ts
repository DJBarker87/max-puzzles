import type { Connector } from '../types'
import type { UnvaluedConnector } from './connectors'
import { coordToKey } from './pathfinder'

/**
 * Result of connector value assignment
 */
export interface ValueAssignmentResult {
  success: boolean
  connectors: Connector[]
  error?: string
}

/**
 * Fisher-Yates shuffle - returns a new shuffled array
 */
export function shuffle<T>(array: T[]): T[] {
  const result = [...array]
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[result[i], result[j]] = [result[j], result[i]]
  }
  return result
}

/**
 * Pick a random element from an array
 */
export function randomChoice<T>(array: T[]): T {
  return array[Math.floor(Math.random() * array.length)]
}

/**
 * Generate a random integer in range [min, max] inclusive
 */
export function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

/**
 * Assign unique values to all connectors
 * Ensures no cell has duplicate connector values
 */
export function assignConnectorValues(
  unvaluedConnectors: UnvaluedConnector[],
  minValue: number,
  maxValue: number
): ValueAssignmentResult {
  // Build map: cellKey -> list of connector indices touching that cell
  const cellConnectorMap = new Map<string, number[]>()

  unvaluedConnectors.forEach((connector, index) => {
    const keyA = coordToKey(connector.cellA)
    const keyB = coordToKey(connector.cellB)

    if (!cellConnectorMap.has(keyA)) {
      cellConnectorMap.set(keyA, [])
    }
    cellConnectorMap.get(keyA)!.push(index)

    if (!cellConnectorMap.has(keyB)) {
      cellConnectorMap.set(keyB, [])
    }
    cellConnectorMap.get(keyB)!.push(index)
  })

  // Create connectors with null values initially
  const connectorValues: (number | null)[] = new Array(unvaluedConnectors.length).fill(null)

  // Process connectors in shuffled order for variety
  const indices = shuffle([...Array(unvaluedConnectors.length).keys()])

  for (const index of indices) {
    const connector = unvaluedConnectors[index]
    const keyA = coordToKey(connector.cellA)
    const keyB = coordToKey(connector.cellB)

    // Collect all values already used by connectors touching cellA or cellB
    const usedValues = new Set<number>()

    const touchingA = cellConnectorMap.get(keyA) || []
    const touchingB = cellConnectorMap.get(keyB) || []

    for (const i of touchingA) {
      if (connectorValues[i] !== null) {
        usedValues.add(connectorValues[i]!)
      }
    }
    for (const i of touchingB) {
      if (connectorValues[i] !== null) {
        usedValues.add(connectorValues[i]!)
      }
    }

    // Find available values
    const available: number[] = []
    for (let v = minValue; v <= maxValue; v++) {
      if (!usedValues.has(v)) {
        available.push(v)
      }
    }

    // No available values = assignment failed
    if (available.length === 0) {
      return {
        success: false,
        connectors: [],
        error: `No available values for connector between ${keyA} and ${keyB}. Used: [${[...usedValues].join(', ')}]`,
      }
    }

    // Randomly select from available values
    connectorValues[index] = randomChoice(available)
  }

  // Convert to proper Connector type
  const connectors: Connector[] = unvaluedConnectors.map((uv, i) => ({
    ...uv,
    value: connectorValues[i]!,
  }))

  return {
    success: true,
    connectors,
  }
}
