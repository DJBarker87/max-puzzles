/**
 * SVG gradient and filter definitions for Circuit Challenge grid
 */
export default function GridDefs() {
  return (
    <defs>
      {/* Normal cell gradients */}
      <linearGradient id="cc-cellTopGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#3a3a4a" />
        <stop offset="100%" stopColor="#252530" />
      </linearGradient>

      <linearGradient id="cc-cellBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#2a2a3a" />
        <stop offset="100%" stopColor="#1a1a25" />
      </linearGradient>

      <linearGradient id="cc-cellEdgeGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#1a1a25" />
        <stop offset="100%" stopColor="#0f0f15" />
      </linearGradient>

      <radialGradient id="cc-cellInnerShadow">
        <stop offset="0%" stopColor="transparent" />
        <stop offset="70%" stopColor="transparent" />
        <stop offset="100%" stopColor="rgba(0,0,0,0.3)" />
      </radialGradient>

      {/* Start cell gradients */}
      <linearGradient id="cc-startGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#15803d" />
        <stop offset="100%" stopColor="#0d5025" />
      </linearGradient>

      <linearGradient id="cc-startBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#0d5025" />
        <stop offset="100%" stopColor="#073518" />
      </linearGradient>

      {/* Finish cell gradients */}
      <linearGradient id="cc-finishGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#ca8a04" />
        <stop offset="100%" stopColor="#854d0e" />
      </linearGradient>

      <linearGradient id="cc-finishBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#854d0e" />
        <stop offset="100%" stopColor="#5c3508" />
      </linearGradient>

      {/* Current position gradients */}
      <linearGradient id="cc-currentGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#0d9488" />
        <stop offset="100%" stopColor="#086560" />
      </linearGradient>

      <linearGradient id="cc-currentBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#086560" />
        <stop offset="100%" stopColor="#054540" />
      </linearGradient>

      {/* Visited cell gradients */}
      <linearGradient id="cc-visitedGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#1a5c38" />
        <stop offset="100%" stopColor="#103822" />
      </linearGradient>

      <linearGradient id="cc-visitedBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#103822" />
        <stop offset="100%" stopColor="#082515" />
      </linearGradient>

      {/* Wrong answer gradient */}
      <linearGradient id="cc-wrongGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#ef4444" />
        <stop offset="100%" stopColor="#b91c1c" />
      </linearGradient>

      <linearGradient id="cc-wrongBaseGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#b91c1c" />
        <stop offset="100%" stopColor="#7f1d1d" />
      </linearGradient>

      {/* Filters */}
      <filter id="cc-glowFilter" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>

      <filter id="cc-connectorGlowFilter" x="-100%" y="-100%" width="300%" height="300%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="6" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>

      <filter id="cc-shadowFilter" x="-20%" y="-20%" width="140%" height="140%">
        <feGaussianBlur in="SourceAlpha" stdDeviation="3" result="blur" />
        <feOffset in="blur" dx="2" dy="3" result="offsetBlur" />
        <feMerge>
          <feMergeNode in="offsetBlur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
    </defs>
  )
}
