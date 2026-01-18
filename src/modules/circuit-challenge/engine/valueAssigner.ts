import type { Connector, Coordinate } from '../types'
import type { UnvaluedConnector } from './connectors'
import { coordToKey } from './pathfinder'

/**
 * Result of connector value assignment
 */
export interface ValueAssignmentResult {
  success: boolean
  connectors: Connector[]
  /** Indices of connectors reserved for division (have values 1-13) */
  divisionConnectorIndices: number[]
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
 * Maximum value for division-friendly answers
 */
const MAX_DIVISION_VALUE = 13

/**
 * Proportion of path connectors reserved for division when enabled
 */
const DIVISION_CONNECTOR_RATIO = 0.25

/**
 * Check if a connector is on the solution path
 * A connector is on the path if it connects two adjacent cells in the path sequence
 */
function isConnectorOnPath(connector: UnvaluedConnector, path: Coordinate[]): boolean {
  for (let i = 0; i < path.length - 1; i++) {
    const current = path[i]
    const next = path[i + 1]

    // Check if connector connects current to next (in either direction)
    const matchesForward =
      connector.cellA.row === current.row && connector.cellA.col === current.col &&
      connector.cellB.row === next.row && connector.cellB.col === next.col
    const matchesBackward =
      connector.cellA.row === next.row && connector.cellA.col === next.col &&
      connector.cellB.row === current.row && connector.cellB.col === current.col

    if (matchesForward || matchesBackward) {
      return true
    }
  }
  return false
}

/**
 * Assign a value to a single connector, respecting uniqueness constraints
 */
function assignValueToConnector(
  index: number,
  unvaluedConnectors: UnvaluedConnector[],
  connectorValues: (number | null)[],
  cellConnectorMap: Map<string, number[]>,
  minValue: number,
  maxValue: number,
  preferSmall: boolean = false
): number | null {
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

  // Find available values in the specified range
  const available: number[] = []
  for (let v = minValue; v <= maxValue; v++) {
    if (!usedValues.has(v)) {
      available.push(v)
    }
  }

  if (available.length === 0) {
    return null
  }

  // If preferring small values, filter to small values if possible
  if (preferSmall) {
    const smallValues = available.filter(v => v <= MAX_DIVISION_VALUE)
    if (smallValues.length > 0) {
      return randomChoice(smallValues)
    }
  }

  return randomChoice(available)
}

/**
 * Assign unique values to all connectors
 * Ensures no cell has duplicate connector values
 *
 * When divisionEnabled is true and a solution path is provided:
 * - ~25% of path connectors are reserved for division (values 1-13)
 * - These are assigned first to ensure division-friendly cell answers
 */
export function assignConnectorValues(
  unvaluedConnectors: UnvaluedConnector[],
  minValue: number,
  maxValue: number,
  divisionEnabled: boolean = false,
  solutionPath: Coordinate[] = []
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

  // When division is enabled, identify path connectors and reserve some for division
  let divisionConnectorIndices: number[] = []

  if (divisionEnabled && solutionPath.length > 1) {
    // Find all connectors that are on the solution path
    const pathConnectorIndices: number[] = []
    unvaluedConnectors.forEach((connector, index) => {
      if (isConnectorOnPath(connector, solutionPath)) {
        pathConnectorIndices.push(index)
      }
    })

    // Reserve ~25% of path connectors for division
    const numDivisionConnectors = Math.max(1, Math.floor(pathConnectorIndices.length * DIVISION_CONNECTOR_RATIO))
    const shuffledPathIndices = shuffle(pathConnectorIndices)
    divisionConnectorIndices = shuffledPathIndices.slice(0, numDivisionConnectors)

    // Assign division connectors FIRST with small values (1-13)
    for (const index of divisionConnectorIndices) {
      const value = assignValueToConnector(
        index,
        unvaluedConnectors,
        connectorValues,
        cellConnectorMap,
        Math.max(1, minValue), // Ensure min is at least 1 for division
        Math.min(MAX_DIVISION_VALUE, maxValue), // Cap at 13 for division
        true // Prefer small values
      )

      if (value === null) {
        // Try with full range as fallback
        const fallbackValue = assignValueToConnector(
          index,
          unvaluedConnectors,
          connectorValues,
          cellConnectorMap,
          minValue,
          maxValue,
          false
        )
        if (fallbackValue === null) {
          const connector = unvaluedConnectors[index]
          return {
            success: false,
            connectors: [],
            divisionConnectorIndices: [],
            error: `No available values for division connector between ${coordToKey(connector.cellA)} and ${coordToKey(connector.cellB)}`,
          }
        }
        connectorValues[index] = fallbackValue
      } else {
        connectorValues[index] = value
      }
    }
  }

  // Create set of already-assigned indices for quick lookup
  const assignedIndices = new Set(divisionConnectorIndices)

  // Assign remaining connectors in shuffled order
  const remainingIndices = shuffle(
    [...Array(unvaluedConnectors.length).keys()].filter(i => !assignedIndices.has(i))
  )

  for (const index of remainingIndices) {
    const value = assignValueToConnector(
      index,
      unvaluedConnectors,
      connectorValues,
      cellConnectorMap,
      minValue,
      maxValue,
      false
    )

    if (value === null) {
      const connector = unvaluedConnectors[index]
      return {
        success: false,
        connectors: [],
        divisionConnectorIndices: [],
        error: `No available values for connector between ${coordToKey(connector.cellA)} and ${coordToKey(connector.cellB)}`,
      }
    }
    connectorValues[index] = value
  }

  // Convert to proper Connector type
  const connectors: Connector[] = unvaluedConnectors.map((uv, i) => ({
    ...uv,
    value: connectorValues[i]!,
  }))

  return {
    success: true,
    connectors,
    divisionConnectorIndices,
  }
}
