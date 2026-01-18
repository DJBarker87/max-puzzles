import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button, Card, Modal, Toggle } from '@/ui'
import { StarryBackground, PuzzlePreview } from '../components'
import { generatePrintablePuzzles } from '../services/printGenerator'
import { renderAllPages } from '../services/svgRenderer'
import { openPrintPreview, openPreview } from '../services/pdfGenerator'
import {
  DEFAULT_PRINT_CONFIG,
  DIFFICULTY_NAMES,
  type PrintConfig,
  type PrintablePuzzle,
} from '../types/print'

/**
 * Puzzle Maker screen for generating printable worksheets.
 */
export default function PuzzleMakerScreen() {
  const navigate = useNavigate()

  // Configuration state
  const [config, setConfig] = useState<PrintConfig>(DEFAULT_PRINT_CONFIG)

  // Generation state
  const [puzzles, setPuzzles] = useState<PrintablePuzzle[]>([])
  const [isGenerating, setIsGenerating] = useState(false)
  const [isExporting, setIsExporting] = useState(false)
  const [previewIndex, setPreviewIndex] = useState(0)

  // Modal state
  const [showPreviewModal, setShowPreviewModal] = useState(false)

  // Update config helper
  const updateConfig = (updates: Partial<PrintConfig>) => {
    setConfig((prev) => ({ ...prev, ...updates }))
    // Clear puzzles when config changes
    setPuzzles([])
  }

  // Generate puzzles
  const handleGenerate = useCallback(() => {
    setIsGenerating(true)

    // Use setTimeout to allow UI to update
    setTimeout(() => {
      try {
        const newPuzzles = generatePrintablePuzzles(config)
        setPuzzles(newPuzzles)
        setPreviewIndex(0)
      } catch (err) {
        console.error('Error generating puzzles:', err)
      } finally {
        setIsGenerating(false)
      }
    }, 100)
  }, [config])

  // Print / Export to PDF
  const handlePrint = useCallback(() => {
    if (puzzles.length === 0) return

    setIsExporting(true)

    try {
      // Render all pages
      const { questionPages, answerPages } = renderAllPages(puzzles, config)

      // Open print preview
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

  // Calculate stats
  const totalPages = Math.ceil(puzzles.length / config.puzzlesPerPage)
  const totalPagesWithAnswers = config.showAnswers ? totalPages * 2 + 1 : totalPages

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

        {/* Configuration */}
        <Card className="p-4 mb-6">
          <h3 className="font-bold mb-4">Puzzle Settings</h3>

          {/* Difficulty */}
          <div className="mb-4">
            <label className="block text-sm font-medium mb-2">
              Difficulty Level
            </label>
            <select
              value={config.difficulty}
              onChange={(e) => updateConfig({ difficulty: Number(e.target.value) })}
              className="w-full px-3 py-2 rounded-lg bg-background-dark border border-white/20 focus:border-accent-primary outline-none text-white"
            >
              {Object.entries(DIFFICULTY_NAMES).map(([level, name]) => (
                <option key={level} value={level}>
                  {name} (Level {Number(level) + 1})
                </option>
              ))}
            </select>
          </div>

          {/* Puzzle Count */}
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
            disabled={isGenerating}
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
