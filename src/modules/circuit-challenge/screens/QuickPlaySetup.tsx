import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button, Card, Toggle, Slider } from '@/ui'
import { StarryBackground } from '../components'
import {
  DIFFICULTY_PRESETS,
  createCustomDifficulty,
  calculateMinPathLength,
  calculateMaxPathLength,
} from '../engine/difficulty'
import type { DifficultySettings } from '../engine/types'

/**
 * Get human-readable description of a difficulty preset
 */
function getPresetDescription(preset: DifficultySettings): string {
  const ops: string[] = []
  if (preset.additionEnabled) ops.push('addition')
  if (preset.subtractionEnabled) ops.push('subtraction')
  if (preset.multiplicationEnabled) ops.push('multiplication')
  if (preset.divisionEnabled) ops.push('division')

  const opsStr = ops.length === 1 ? ops[0] : ops.slice(0, -1).join(', ') + ' & ' + ops[ops.length - 1]

  return `${opsStr.charAt(0).toUpperCase() + opsStr.slice(1)}, numbers up to ${preset.addSubRange}, ${preset.gridRows}×${preset.gridCols} grid`
}

/**
 * Quick Play setup screen for selecting difficulty
 */
export default function QuickPlaySetup() {
  const navigate = useNavigate()

  const [selectedPreset, setSelectedPreset] = useState(4) // Default to Level 5
  const [isCustomMode, setIsCustomMode] = useState(false)
  const [hiddenMode, setHiddenMode] = useState(false)

  // Custom settings start as a copy of the selected preset
  const [customSettings, setCustomSettings] = useState<Partial<DifficultySettings>>({
    additionEnabled: true,
    subtractionEnabled: true,
    multiplicationEnabled: false,
    divisionEnabled: false,
    addSubRange: 20,
    multDivRange: 5,
    gridRows: 4,
    gridCols: 5,
  })

  const currentPreset = DIFFICULTY_PRESETS[selectedPreset]

  // Build the final difficulty settings
  const finalDifficulty = useMemo<DifficultySettings>(() => {
    if (isCustomMode) {
      const settings = createCustomDifficulty({
        ...customSettings,
        hiddenMode,
      })
      // Recalculate path lengths
      settings.minPathLength = calculateMinPathLength(settings.gridRows, settings.gridCols)
      settings.maxPathLength = calculateMaxPathLength(settings.gridRows, settings.gridCols)
      return settings
    } else {
      const preset = { ...currentPreset }
      preset.hiddenMode = hiddenMode
      preset.minPathLength = calculateMinPathLength(preset.gridRows, preset.gridCols)
      preset.maxPathLength = calculateMaxPathLength(preset.gridRows, preset.gridCols)
      return preset
    }
  }, [isCustomMode, customSettings, currentPreset, hiddenMode])

  const handleStart = () => {
    navigate('/play/circuit-challenge/game', {
      state: { difficulty: finalDifficulty },
    })
  }

  const toggleOperation = (op: string) => {
    switch (op) {
      case '+':
        setCustomSettings(s => ({ ...s, additionEnabled: !s.additionEnabled }))
        break
      case '−':
        setCustomSettings(s => ({ ...s, subtractionEnabled: !s.subtractionEnabled }))
        break
      case '×':
        setCustomSettings(s => ({ ...s, multiplicationEnabled: !s.multiplicationEnabled }))
        break
      case '÷':
        setCustomSettings(s => ({ ...s, divisionEnabled: !s.divisionEnabled }))
        break
    }
  }

  const isOperationEnabled = (op: string): boolean => {
    switch (op) {
      case '+': return customSettings.additionEnabled ?? true
      case '−': return customSettings.subtractionEnabled ?? false
      case '×': return customSettings.multiplicationEnabled ?? false
      case '÷': return customSettings.divisionEnabled ?? false
      default: return false
    }
  }

  // Check if at least one operation is enabled
  const hasValidOperations = isCustomMode
    ? (customSettings.additionEnabled || customSettings.subtractionEnabled ||
       customSettings.multiplicationEnabled || customSettings.divisionEnabled)
    : true

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      <div className="relative z-10 flex-1 p-4 md:p-8 max-w-2xl mx-auto w-full">
        {/* Header */}
        <div className="flex items-center gap-4 mb-8">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate('/play/circuit-challenge')}
            className="w-11 h-11 rounded-xl !p-0 flex items-center justify-center"
            aria-label="Go back"
          >
            <span className="text-xl">←</span>
          </Button>
          <h1 className="text-2xl font-display font-bold">Quick Play</h1>
        </div>

        {/* Difficulty Selection */}
        <Card className="mb-6 p-4">
          <h2 className="text-lg font-bold mb-4">Difficulty</h2>

          <select
            value={selectedPreset}
            onChange={(e) => setSelectedPreset(Number(e.target.value))}
            disabled={isCustomMode}
            className="w-full p-3 rounded-lg bg-background-dark border border-white/20 text-white disabled:opacity-50"
          >
            {DIFFICULTY_PRESETS.map((preset, i) => (
              <option key={i} value={i}>
                Level {i + 1}: {preset.name}
              </option>
            ))}
          </select>

          <p className="mt-2 text-text-secondary text-sm">
            {getPresetDescription(currentPreset)}
          </p>
        </Card>

        {/* Custom Settings Toggle */}
        <Card className="mb-6 p-4">
          <Toggle
            checked={isCustomMode}
            onChange={setIsCustomMode}
            label="Customise Settings"
          />

          {isCustomMode && (
            <div className="mt-6 space-y-6">
              {/* Operations checkboxes */}
              <div>
                <label className="text-sm font-medium mb-3 block">Operations</label>
                <div className="flex flex-wrap gap-3">
                  {['+', '−', '×', '÷'].map((op) => (
                    <label
                      key={op}
                      className="flex items-center gap-2 cursor-pointer"
                    >
                      <input
                        type="checkbox"
                        checked={isOperationEnabled(op)}
                        onChange={() => toggleOperation(op)}
                        className="w-5 h-5 rounded accent-accent-primary"
                      />
                      <span className="text-lg">{op}</span>
                    </label>
                  ))}
                </div>
                {!hasValidOperations && (
                  <p className="text-error text-sm mt-2">
                    At least one operation must be enabled
                  </p>
                )}
              </div>

              {/* Add/Sub Range slider */}
              <Slider
                label="+/− Number Range"
                min={5}
                max={100}
                value={customSettings.addSubRange ?? 20}
                onChange={(v) => setCustomSettings((s) => ({ ...s, addSubRange: v }))}
                showValue
              />

              {/* Mult/Div Range slider (if enabled) */}
              {(customSettings.multiplicationEnabled || customSettings.divisionEnabled) && (
                <Slider
                  label="×/÷ Number Range"
                  min={2}
                  max={12}
                  value={customSettings.multDivRange ?? 5}
                  onChange={(v) => setCustomSettings((s) => ({ ...s, multDivRange: v }))}
                  showValue
                />
              )}

              {/* Grid size selectors */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium mb-2 block">Rows</label>
                  <div className="flex flex-wrap gap-2">
                    {[3, 4, 5, 6, 7, 8].map((n) => (
                      <button
                        key={n}
                        onClick={() => setCustomSettings((s) => ({ ...s, gridRows: n }))}
                        className={`w-10 h-10 rounded transition-colors ${
                          customSettings.gridRows === n
                            ? 'bg-accent-primary text-white'
                            : 'bg-background-dark border border-white/20 hover:border-white/40'
                        }`}
                      >
                        {n}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium mb-2 block">Columns</label>
                  <div className="flex flex-wrap gap-2">
                    {[4, 5, 6, 7, 8, 9, 10].map((n) => (
                      <button
                        key={n}
                        onClick={() => setCustomSettings((s) => ({ ...s, gridCols: n }))}
                        className={`w-10 h-10 rounded transition-colors ${
                          customSettings.gridCols === n
                            ? 'bg-accent-primary text-white'
                            : 'bg-background-dark border border-white/20 hover:border-white/40'
                        }`}
                      >
                        {n}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}
        </Card>

        {/* Hidden Mode Toggle */}
        <Card className="mb-8 p-4">
          <Toggle
            checked={hiddenMode}
            onChange={setHiddenMode}
            label="Hidden Mode"
          />
          <p className="mt-2 text-text-secondary text-sm">
            Mistakes aren't revealed until the end. No lives - always reach FINISH.
          </p>
        </Card>

        {/* Start Button */}
        <Button
          variant="primary"
          size="lg"
          fullWidth
          onClick={handleStart}
          disabled={!hasValidOperations}
        >
          Start Puzzle
        </Button>
      </div>
    </div>
  )
}
