import { useState, useCallback, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button, Card, Modal, Toggle, Slider } from '@/ui'
import { StarryBackground, PuzzlePreview } from '../components'
import { generatePrintablePuzzlesWithSettings } from '../services/printGenerator'
import { renderAllPages } from '../services/svgRenderer'
import { openPrintPreview, openPreview } from '../services/pdfGenerator'
import {
  DIFFICULTY_PRESETS,
  createCustomDifficulty,
  calculateMinPathLength,
  calculateMaxPathLength,
} from '../engine/difficulty'
import type { DifficultySettings } from '../engine/types'
import {
  DEFAULT_PRINT_CONFIG,
  type PrintConfig,
  type PrintablePuzzle,
} from '../types/print'

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
 * Puzzle Maker screen for generating printable worksheets.
 */
export default function PuzzleMakerScreen() {
  const navigate = useNavigate()

  // Configuration state
  const [config, setConfig] = useState<PrintConfig>(DEFAULT_PRINT_CONFIG)
  const [selectedPreset, setSelectedPreset] = useState(3) // Default to Level 4
  const [isCustomMode, setIsCustomMode] = useState(false)

  // Custom settings
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

  // Generation state
  const [puzzles, setPuzzles] = useState<PrintablePuzzle[]>([])
  const [isGenerating, setIsGenerating] = useState(false)
  const [isExporting, setIsExporting] = useState(false)
  const [previewIndex, setPreviewIndex] = useState(0)

  // Modal state
  const [showPreviewModal, setShowPreviewModal] = useState(false)

  const currentPreset = DIFFICULTY_PRESETS[selectedPreset]

  // Build the final difficulty settings
  const finalDifficulty = useMemo<DifficultySettings>(() => {
    if (isCustomMode) {
      const settings = createCustomDifficulty({
        ...customSettings,
      })
      settings.minPathLength = calculateMinPathLength(settings.gridRows, settings.gridCols)
      settings.maxPathLength = calculateMaxPathLength(settings.gridRows, settings.gridCols)
      return settings
    } else {
      const preset = { ...currentPreset }
      preset.minPathLength = calculateMinPathLength(preset.gridRows, preset.gridCols)
      preset.maxPathLength = calculateMaxPathLength(preset.gridRows, preset.gridCols)
      return preset
    }
  }, [isCustomMode, customSettings, currentPreset])

  // Update config helper
  const updateConfig = (updates: Partial<PrintConfig>) => {
    setConfig((prev) => ({ ...prev, ...updates }))
    setPuzzles([])
  }

  const handlePresetChange = (preset: number) => {
    setSelectedPreset(preset)
    updateConfig({ difficulty: preset })
  }

  // Generate puzzles
  const handleGenerate = useCallback(() => {
    setIsGenerating(true)

    setTimeout(() => {
      try {
        const newPuzzles = generatePrintablePuzzlesWithSettings(config, finalDifficulty)
        setPuzzles(newPuzzles)
        setPreviewIndex(0)
      } catch (err) {
        console.error('Error generating puzzles:', err)
      } finally {
        setIsGenerating(false)
      }
    }, 100)
  }, [config, finalDifficulty])

  // Print / Export to PDF
  const handlePrint = useCallback(() => {
    if (puzzles.length === 0) return

    setIsExporting(true)

    try {
      const { questionPages, answerPages } = renderAllPages(puzzles, config)
      openPrintPreview(questionPages, answerPages, config)
    } catch (err) {
      console.error('Error exporting:', err)
    } finally {
      setIsExporting(false)
    }
  }, [puzzles, config])

  // Preview without printing
  const handlePreview = useCallback(() => {
    if (puzzles.length === 0) return

    setIsExporting(true)

    try {
      const { questionPages, answerPages } = renderAllPages(puzzles, config)
      openPreview(questionPages, answerPages, config)
    } catch (err) {
      console.error('Error previewing:', err)
    } finally {
      setIsExporting(false)
    }
  }, [puzzles, config])

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
    setPuzzles([])
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

  // Calculate stats
  const totalPages = Math.ceil(puzzles.length / config.puzzlesPerPage)

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      <div className="relative z-10 flex-1 p-4 md:p-8 max-w-3xl mx-auto w-full">
        {/* Header */}
        <div className="flex items-center gap-4 mb-6">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate('/play/circuit-challenge')}
            className="w-11 h-11 rounded-xl !p-0 flex items-center justify-center"
            aria-label="Go back"
          >
            <span className="text-xl">←</span>
          </Button>
          <h1 className="text-2xl font-display font-bold">Puzzle Maker</h1>
        </div>

        {/* Introduction */}
        <Card className="mb-6 p-4">
          <h2 className="text-lg font-bold mb-2">Create Printable Puzzles</h2>
          <p className="text-text-secondary text-sm">
            Generate Circuit Challenge puzzles to print.
            Each A4 page contains 2 puzzles.
          </p>
        </Card>

        {/* Difficulty Selection */}
        <Card className="mb-6 p-4">
          <h3 className="font-bold mb-4">Difficulty</h3>

          <select
            value={selectedPreset}
            onChange={(e) => handlePresetChange(Number(e.target.value))}
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
            onChange={(checked) => {
              setIsCustomMode(checked)
              setPuzzles([])
            }}
            label="Custom Settings"
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
                onChange={(v) => {
                  setCustomSettings((s) => ({ ...s, addSubRange: v }))
                  setPuzzles([])
                }}
                showValue
              />

              {/* Mult/Div Range slider (if enabled) */}
              {(customSettings.multiplicationEnabled || customSettings.divisionEnabled) && (
                <Slider
                  label="×/÷ Number Range"
                  min={2}
                  max={12}
                  value={customSettings.multDivRange ?? 5}
                  onChange={(v) => {
                    setCustomSettings((s) => ({ ...s, multDivRange: v }))
                    setPuzzles([])
                  }}
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
                        onClick={() => {
                          setCustomSettings((s) => ({ ...s, gridRows: n }))
                          setPuzzles([])
                        }}
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
                        onClick={() => {
                          setCustomSettings((s) => ({ ...s, gridCols: n }))
                          setPuzzles([])
                        }}
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

              {/* Custom description */}
              <p className="text-text-secondary text-sm">
                {getPresetDescription(finalDifficulty)}
              </p>
            </div>
          )}
        </Card>

        {/* Puzzle Count */}
        <Card className="p-4 mb-6">
          <h3 className="font-bold mb-4">Puzzle Count</h3>

          <div className="mb-4">
            <label className="block text-sm font-medium mb-2">
              Number of Puzzles: {config.puzzleCount}
            </label>
            <input
              type="range"
              min={2}
              max={50}
              step={2}
              value={config.puzzleCount}
              onChange={(e) => updateConfig({ puzzleCount: Number(e.target.value) })}
              className="w-full accent-accent-primary"
            />
            <div className="flex justify-between text-xs text-text-secondary">
              <span>2</span>
              <span>50</span>
            </div>
          </div>

          {/* Include Answers */}
          <Toggle
            checked={config.showAnswers}
            onChange={(checked) => updateConfig({ showAnswers: checked })}
            label="Include answer key pages"
          />
        </Card>

        {/* Generate Button */}
        <div className="mb-6">
          <Button
            variant="primary"
            fullWidth
            size="lg"
            onClick={handleGenerate}
            loading={isGenerating}
            disabled={isGenerating || !hasValidOperations}
          >
            {isGenerating
              ? 'Generating Puzzles...'
              : `Generate ${config.puzzleCount} Puzzles`}
          </Button>
        </div>

        {/* Preview Section */}
        {puzzles.length > 0 && (
          <Card className="p-4 mb-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold">Preview</h3>
              <span className="text-sm text-text-secondary">
                {puzzles.length} puzzles &bull; {totalPages} pages
                {config.showAnswers && ` + ${totalPages} answer pages`}
              </span>
            </div>

            {/* Puzzle Navigator */}
            <div className="flex items-center justify-between mb-4">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setPreviewIndex(Math.max(0, previewIndex - 1))}
                disabled={previewIndex === 0}
              >
                &larr; Previous
              </Button>

              <span className="text-sm">
                Puzzle {previewIndex + 1} of {puzzles.length}
              </span>

              <Button
                variant="ghost"
                size="sm"
                onClick={() =>
                  setPreviewIndex(Math.min(puzzles.length - 1, previewIndex + 1))
                }
                disabled={previewIndex === puzzles.length - 1}
              >
                Next &rarr;
              </Button>
            </div>

            {/* Puzzle Preview */}
            <div className="bg-white rounded-lg p-4 mb-4 overflow-auto">
              <PuzzlePreview
                puzzle={puzzles[previewIndex]}
                config={config}
                showSolution={false}
              />
            </div>

            {/* Full Page Preview Button */}
            <Button
              variant="secondary"
              fullWidth
              onClick={() => setShowPreviewModal(true)}
            >
              Full Page Preview
            </Button>
          </Card>
        )}

        {/* Export Buttons */}
        {puzzles.length > 0 && (
          <div className="space-y-3">
            <Button
              variant="primary"
              fullWidth
              size="lg"
              onClick={handlePrint}
              loading={isExporting}
              disabled={isExporting}
            >
              Print Puzzles
            </Button>

            <Button
              variant="secondary"
              fullWidth
              onClick={handlePreview}
              disabled={isExporting}
            >
              Preview in Browser
            </Button>
          </div>
        )}

      </div>

      {/* Full Page Preview Modal */}
      <Modal
        isOpen={showPreviewModal}
        onClose={() => setShowPreviewModal(false)}
        title="Page Preview"
        size="lg"
      >
        <div className="bg-white rounded-lg p-2 overflow-auto max-h-[60vh]">
          {/* Render a sample page preview */}
          {puzzles.length >= 2 ? (
            <div className="space-y-4">
              <PuzzlePreview
                puzzle={puzzles[0]}
                config={config}
                showSolution={false}
              />
              <div className="border-t border-gray-200 pt-4">
                <PuzzlePreview
                  puzzle={puzzles[1]}
                  config={config}
                  showSolution={false}
                />
              </div>
            </div>
          ) : puzzles.length === 1 ? (
            <PuzzlePreview
              puzzle={puzzles[0]}
              config={config}
              showSolution={false}
            />
          ) : (
            <p className="text-gray-500 text-center py-8">
              Generate puzzles to see preview
            </p>
          )}
        </div>
      </Modal>
    </div>
  )
}
