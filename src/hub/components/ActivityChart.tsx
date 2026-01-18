import { useState, useEffect } from 'react'
import { getActivityChartData } from '@/shared/services/dashboard'
import type { TimePeriod, ChartMetric, ChartData } from '../types/dashboard'

interface ActivityChartProps {
  childId: string
  period: TimePeriod
}

/**
 * Activity chart component with metric selection.
 * Displays daily aggregated data as a bar chart.
 */
export default function ActivityChart({ childId, period }: ActivityChartProps) {
  const [metric, setMetric] = useState<ChartMetric>('games')
  const [chartData, setChartData] = useState<ChartData | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Load chart data when childId, period, or metric changes
  useEffect(() => {
    let cancelled = false

    async function loadData() {
      setIsLoading(true)

      try {
        const data = await getActivityChartData(childId, metric, period)
        if (!cancelled) {
          setChartData(data)
        }
      } catch (err) {
        console.error('Failed to load chart data:', err)
      } finally {
        if (!cancelled) {
          setIsLoading(false)
        }
      }
    }

    loadData()

    return () => {
      cancelled = true
    }
  }, [childId, period, metric])

  // Metric configuration
  const metrics: { key: ChartMetric; label: string; unit: string; color: string }[] = [
    { key: 'games', label: 'Games', unit: '', color: 'bg-accent-primary' },
    { key: 'time', label: 'Time', unit: 'min', color: 'bg-accent-secondary' },
    { key: 'accuracy', label: 'Accuracy', unit: '%', color: 'bg-green-500' },
    { key: 'coins', label: 'Coins', unit: '', color: 'bg-accent-tertiary' },
  ]

  const currentMetricConfig = metrics.find((m) => m.key === metric)!

  // Calculate display values
  const maxValue = chartData?.maxValue || 1
  const hasData = chartData?.points.some((p) => p.value > 0) || false

  return (
    <div>
      {/* Metric Selector Tabs */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {metrics.map((m) => (
          <button
            key={m.key}
            onClick={() => setMetric(m.key)}
            className={`
              px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-all
              ${
                metric === m.key
                  ? `${m.color} text-black`
                  : 'bg-background-dark text-text-secondary hover:bg-background-light'
              }
            `}
          >
            {m.label}
          </button>
        ))}
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="h-48 flex items-center justify-center">
          <div className="text-text-secondary animate-pulse">Loading chart...</div>
        </div>
      )}

      {/* Chart */}
      {!isLoading && chartData && (
        <>
          {/* Summary Stats */}
          <div className="flex justify-between items-center mb-4 text-sm">
            <div className="text-text-secondary">
              Total:{' '}
              <span className="font-bold text-white">
                {chartData.total}
                {currentMetricConfig.unit}
              </span>
            </div>
            <div className="text-text-secondary">
              Average:{' '}
              <span className="font-bold text-white">
                {chartData.average}
                {currentMetricConfig.unit}/day
              </span>
            </div>
          </div>

          {/* Bar Chart */}
          <div className="relative h-48">
            {!hasData ? (
              /* No Data State */
              <div className="absolute inset-0 flex items-center justify-center">
                <p className="text-text-secondary">No activity for this period</p>
              </div>
            ) : (
              /* Bars */
              <div className="h-full flex items-end gap-1">
                {chartData.points.map((point) => {
                  const heightPercent = maxValue > 0 ? (point.value / maxValue) * 100 : 0

                  // Ensure minimum visible height if there's any value
                  const displayHeight = point.value > 0 ? Math.max(heightPercent, 8) : 0

                  return (
                    <div
                      key={point.date}
                      className="flex-1 flex flex-col items-center justify-end h-full"
                    >
                      {/* Value Label (only show if non-zero and enough space) */}
                      {point.value > 0 && (
                        <span className="text-xs text-text-secondary mb-1 tabular-nums">
                          {point.value}
                          {metric === 'accuracy' && '%'}
                        </span>
                      )}

                      {/* Bar */}
                      <div
                        className={`
                          w-full rounded-t-sm transition-all duration-300 ease-out
                          ${currentMetricConfig.color}
                          ${point.value === 0 ? 'bg-background-light' : ''}
                        `}
                        style={{
                          height: point.value > 0 ? `${displayHeight}%` : '2px',
                          minHeight: point.value > 0 ? '8px' : '2px',
                        }}
                        title={`${point.dateLabel}: ${point.value}${currentMetricConfig.unit}`}
                      />

                      {/* Date Label */}
                      <span className="text-xs text-text-secondary mt-2 truncate w-full text-center">
                        {point.dateLabel}
                      </span>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Y-axis reference line (optional) */}
          {hasData && (
            <div className="flex justify-between text-xs text-text-secondary mt-2 px-1">
              <span>0</span>
              <span>
                {maxValue}
                {currentMetricConfig.unit}
              </span>
            </div>
          )}
        </>
      )}
    </div>
  )
}
