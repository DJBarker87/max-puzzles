/**
 * Theme constants for Max's Puzzles
 * These values mirror the Tailwind config for use in JS/TS
 */

export const colors = {
  background: {
    dark: '#0f0f23',
    mid: '#1a1a3e',
    light: '#252550',
  },
  accent: {
    primary: '#22c55e',
    secondary: '#e94560',
    tertiary: '#fbbf24',
  },
  circuit: {
    cell: {
      normal: '#3a3a4a',
      edge: '#1a1a25',
    },
    start: '#15803d',
    finish: '#ca8a04',
    current: '#0d9488',
    visited: '#1a5c38',
    connector: {
      default: '#3d3428',
      active: '#00dd77',
      glow: '#00ff88',
    },
  },
  text: {
    primary: '#ffffff',
    secondary: '#a1a1aa',
  },
  error: '#ef4444',
  hearts: {
    active: '#ff3366',
    inactive: '#2a2a3a',
  },
} as const

export const fonts = {
  display: ['Nunito', 'Quicksand', 'sans-serif'],
  body: ['Inter', 'system-ui', 'sans-serif'],
} as const

export const gradients = {
  gridBackground: `linear-gradient(135deg, #0a0a12 0%, #0d0d18 100%)`,
  cellNormal: `linear-gradient(180deg, #3a3a4a 0%, #252530 100%)`,
  cellStart: `linear-gradient(180deg, #15803d 0%, #0d5025 100%)`,
  cellFinish: `linear-gradient(180deg, #ca8a04 0%, #854d0e 100%)`,
  cellCurrent: `linear-gradient(180deg, #0d9488 0%, #086560 100%)`,
  cellVisited: `linear-gradient(180deg, #1a5c38 0%, #103822 100%)`,
} as const

export default {
  colors,
  fonts,
  gradients,
}
