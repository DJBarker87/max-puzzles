import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useSound } from "@/app/providers/SoundProvider";
import Header from "@/hub/components/Header";
import { SplashBackground } from "../components";
import { StarDisplay } from "../components/StarReveal";
import { chapterAliens } from "@/shared/types/chapterAlien";
import {
  getStoryProgress,
  isChapterUnlocked,
  isLevelCompleted,
  getStarsForLevel,
  getStarsInChapter,
  getBestTimeForLevel,
  type StoryProgressData,
} from "@/shared/types/storyProgress";
import "./LevelSelect.css";

// Chapter color themes
const chapterColors: Record<number, string> = {
  1: "#4ade80", // Bob - Green
  2: "#60a5fa", // Blink - Blue
  3: "#c084fc", // Drift - Purple
  4: "#fb923c", // Fuzz - Orange
  5: "#f472b6", // Prism - Pink
  6: "#fbbf24", // Nova - Yellow/Gold
  7: "#f87171", // Clicker - Red
  8: "#2dd4bf", // Bolt - Teal
  9: "#94a3b8", // Sage - Silver
  10: "#fcd34d", // Bibomic - Gold
};

/**
 * Level selection screen with large horizontal hexagon tiles
 * Current level has green glow pulse animation with 5-layer electric flow
 */
export default function LevelSelect() {
  const navigate = useNavigate();
  const { playMusic } = useSound();
  const { chapterId } = useParams<{ chapterId: string }>();
  const chapter = parseInt(chapterId || "1", 10);

  const [progress, setProgress] = useState<StoryProgressData>({
    levelProgress: {},
  });

  const alien = chapterAliens.find((a) => a.chapter === chapter);
  const accentColor = chapterColors[chapter] || "#22c55e";

  // Continue hub music on this screen
  useEffect(() => {
    playMusic("hub", true);
  }, [playMusic]);

  useEffect(() => {
    setProgress(getStoryProgress());
  }, []);

  if (!alien) {
    return <div>Chapter not found</div>;
  }

  const handleLevelClick = (level: number) => {
    if (isLevelUnlocked(level)) {
      navigate(`/play/circuit-challenge/story/${chapter}/${level}`);
    }
  };

  // Level unlocks when previous level is completed
  const isLevelUnlocked = (level: number): boolean => {
    if (!isChapterUnlocked(chapter, progress)) return false;
    if (level === 1) return true;
    return isLevelCompleted(chapter, level - 1, progress);
  };

  // Current level is first unlocked but not completed
  const isCurrentLevel = (level: number): boolean => {
    if (!isLevelUnlocked(level)) return false;
    if (isLevelCompleted(chapter, level, progress)) return false;
    // Check if all previous levels are completed
    for (let prev = 1; prev < level; prev++) {
      if (!isLevelCompleted(chapter, prev, progress)) {
        return false;
      }
    }
    return true;
  };

  const isHiddenMode = (level: number): boolean => {
    return level === 5 || chapter === 10;
  };

  const totalStars = getStarsInChapter(chapter, progress);
  const completedLevels = [1, 2, 3, 4, 5].filter((l) =>
    isLevelCompleted(chapter, l, progress)
  ).length;

  return (
    <div className="h-screen flex flex-col relative overflow-hidden">
      <SplashBackground overlayOpacity={0.5} />

      <Header showMenu className="relative z-10 shrink-0" />

      {/* Alien Top Trumps Card Header */}
      <div className="px-4 py-3 relative z-10 shrink-0">
        <div
          className="flex items-center gap-3 p-4 rounded-2xl"
          style={{
            backgroundColor: "rgba(26, 26, 62, 0.85)",
            border: `2px solid ${accentColor}50`,
            boxShadow: `0 0 12px ${accentColor}30`,
          }}
        >
          {/* Alien image with glow */}
          <div className="relative">
            <div
              className="absolute inset-0 rounded-full blur-xl opacity-50 animate-pulse"
              style={{ backgroundColor: accentColor }}
            />
            <img
              src={alien.imagePath}
              alt={alien.name}
              className="w-20 h-20 object-contain relative z-10"
            />
          </div>

          {/* Name and traits */}
          <div className="flex-1">
            <span
              className="text-xs font-bold px-2 py-1 rounded"
              style={{
                color: accentColor,
                backgroundColor: `${accentColor}20`,
              }}
            >
              CHAPTER {chapter}
            </span>
            <h1
              className="text-2xl font-black text-white mt-1"
              style={{
                textShadow: `0 0 8px ${accentColor}80, 0 0 4px ${accentColor}50`,
              }}
            >
              {alien.name.toUpperCase()}
            </h1>
            <div className="flex gap-2 mt-1">
              {alien.words.map((word) => (
                <span
                  key={word}
                  className="text-xs font-semibold text-white px-2 py-1 rounded-lg"
                  style={{ backgroundColor: `${accentColor}40` }}
                >
                  {word}
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Horizontal level path - fills screen width */}
      <div className="flex-1 flex items-center justify-center relative z-10 px-4">
        <div className="flex items-center w-full max-w-[600px] py-8">
          {[1, 2, 3, 4, 5].map((level) => (
            <div key={level} className="flex items-center flex-1">
              {/* Hexagon level tile */}
              <LargeHexTile
                level={level}
                chapter={chapter}
                isUnlocked={isLevelUnlocked(level)}
                isCompleted={isLevelCompleted(chapter, level, progress)}
                isCurrent={isCurrentLevel(level)}
                stars={getStarsForLevel(chapter, level, progress)}
                bestTime={getBestTimeForLevel(chapter, level, progress)}
                isHiddenMode={isHiddenMode(level)}
                onClick={() => handleLevelClick(level)}
              />

              {/* Connector (except after level 5) */}
              {level < 5 && (
                <HorizontalConnector
                  isActive={isLevelUnlocked(level + 1)}
                  isPulsing={isLevelCompleted(chapter, level, progress)}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Chapter stats */}
      <div className="text-center pb-6 relative z-10 shrink-0">
        <div className="flex items-center justify-center gap-1 mb-2">
          <span className="text-accent-tertiary">★</span>
          <span className="text-white font-semibold">{totalStars} / 15</span>
        </div>
        <p className="text-text-secondary text-sm">
          {completedLevels} of 5 levels completed
        </p>
      </div>
    </div>
  );
}

// MARK: - Large Hex Tile

interface LargeHexTileProps {
  level: number;
  chapter: number;
  isUnlocked: boolean;
  isCompleted: boolean;
  isCurrent: boolean;
  stars: number;
  bestTime: number | null;
  isHiddenMode: boolean;
  onClick: () => void;
}

/** Format seconds into MM:SS display */
function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}

function LargeHexTile({
  level,
  isUnlocked,
  isCompleted,
  isCurrent,
  stars,
  bestTime,
  isHiddenMode,
  onClick,
}: LargeHexTileProps) {
  const shouldPulse = isCurrent || isCompleted;

  // Hex points for top face (in 100x100 viewBox, centered)
  const topHexPoints = "50,8 88,30 88,70 50,92 12,70 12,30";
  // 3D layer offsets
  const shadowHexPoints = "50,20 88,42 88,82 50,104 12,82 12,42";
  const edgeHexPoints = "50,16 88,38 88,78 50,100 12,78 12,38";
  const baseHexPoints = "50,12 88,34 88,74 50,96 12,74 12,34";

  // Get gradient colors based on state
  const getGradientColors = () => {
    if (isCompleted) return ["#22c55e", "#16a34a"];
    if (isCurrent) return ["#0d9488", "#086560"];
    if (isUnlocked) return ["#3a3a4a", "#252530"];
    return ["#37415140", "#37415125"];
  };

  const getBorderColor = () => {
    if (shouldPulse) return "#00ff88";
    if (isUnlocked) return "rgba(34,197,94,0.5)";
    return "rgba(107,114,128,0.3)";
  };

  const [c1, c2] = getGradientColors();

  return (
    <button
      onClick={onClick}
      disabled={!isUnlocked}
      className="flex flex-col items-center gap-2 flex-1"
    >
      {/* Hexagon - responsive sizing */}
      <div className="relative w-full aspect-square max-w-[80px] md:max-w-[100px]">
        {/* Single SVG with all layers */}
        <svg
          className="absolute inset-0 w-full h-full overflow-visible"
          viewBox="0 0 100 110"
        >
          <defs>
            <linearGradient id={`hex-top-${level}`} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor={c1} />
              <stop offset="100%" stopColor={c2} />
            </linearGradient>
            <linearGradient id={`hex-edge-${level}`} x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#1a1a25" />
              <stop offset="100%" stopColor="#0f0f15" />
            </linearGradient>
            <linearGradient id={`hex-base-${level}`} x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#2a2a3a" />
              <stop offset="100%" stopColor="#1a1a25" />
            </linearGradient>
            <filter id={`hexGlow-${level}`} x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="4" result="coloredBlur" />
              <feMerge>
                <feMergeNode in="coloredBlur" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>

          {/* Electric glow layers (behind 3D hex) */}
          {shouldPulse && (
            <g>
              {/* Glow blur layer */}
              <polygon
                points={topHexPoints}
                fill="none"
                stroke="#00ff88"
                strokeWidth="8"
                className="level-hex-glow"
                filter={`url(#hexGlow-${level})`}
              />
              {/* Main glow line */}
              <polygon
                points={topHexPoints}
                fill="none"
                stroke="#00dd77"
                strokeWidth="4"
              />
            </g>
          )}

          {/* 3D Shadow */}
          <polygon
            points={shadowHexPoints}
            fill="rgba(0,0,0,0.5)"
          />

          {/* 3D Edge */}
          <polygon
            points={edgeHexPoints}
            fill={`url(#hex-edge-${level})`}
          />

          {/* 3D Base */}
          <polygon
            points={baseHexPoints}
            fill={`url(#hex-base-${level})`}
          />

          {/* Top face */}
          <polygon
            points={topHexPoints}
            fill={`url(#hex-top-${level})`}
            stroke={getBorderColor()}
            strokeWidth="2"
          />

          {/* Rim highlight */}
          <polygon
            points={topHexPoints}
            fill="none"
            stroke="rgba(255,255,255,0.2)"
            strokeWidth="1"
          />

          {/* Energy flow animations on top */}
          {shouldPulse && (
            <g>
              {/* Energy flow slow */}
              <polygon
                points={topHexPoints}
                fill="none"
                stroke="#88ffcc"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeDasharray="8 25"
                className="level-hex-energy-slow"
              />
              {/* Energy flow fast */}
              <polygon
                points={topHexPoints}
                fill="none"
                stroke="white"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeDasharray="5 18"
                className="level-hex-energy-fast"
              />
            </g>
          )}
        </svg>

        {/* Level number or lock */}
        <div className="absolute inset-0 flex flex-col items-center justify-center" style={{ marginTop: '-8%' }}>
          {isUnlocked ? (
            <>
              <span className="text-2xl md:text-3xl font-black text-white drop-shadow-[1px_1px_2px_black]">
                {level}
              </span>
              {isHiddenMode && (
                <svg className="w-3 h-3 md:w-4 md:h-4 mt-0.5 text-accent-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                </svg>
              )}
            </>
          ) : (
            <svg className="w-6 h-6 md:w-8 md:h-8 text-gray-500" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 1C8.676 1 6 3.676 6 7v2H4v14h16V9h-2V7c0-3.324-2.676-6-6-6zm0 2c2.276 0 4 1.724 4 4v2H8V7c0-2.276 1.724-4 4-4zm0 10c1.1 0 2 .9 2 2s-.9 2-2 2-2-.9-2-2 .9-2 2-2z" />
            </svg>
          )}
        </div>
      </div>

      {/* Stars and best time display */}
      <div className="flex flex-col items-center gap-0.5">
        {isCompleted ? (
          <>
            <StarDisplay stars={stars} size="small" />
            {bestTime !== null && (
              <span className="text-[10px] text-text-secondary">
                {formatTime(bestTime)}
              </span>
            )}
          </>
        ) : isUnlocked ? (
          <StarDisplay stars={0} size="small" />
        ) : (
          <span className="text-[10px] text-gray-500">Complete prev</span>
        )}
      </div>
    </button>
  );
}

// MARK: - Horizontal Connector

interface HorizontalConnectorProps {
  isActive: boolean;
  isPulsing: boolean;
}

function HorizontalConnector({ isActive, isPulsing }: HorizontalConnectorProps) {
  return (
    <div className="relative h-6 w-4 md:w-6 flex items-center shrink-0" style={{ marginTop: '-10%' }}>
      <svg className="absolute inset-0 w-full h-full" viewBox="0 0 24 24">
        {isPulsing ? (
          <>
            {/* Layer 1: Glow */}
            <line
              x1="0" y1="12" x2="24" y2="12"
              stroke="#00ff88"
              strokeWidth="8"
              strokeLinecap="round"
              className="level-connector-glow"
              filter="url(#connectorGlowFilter)"
            />

            {/* Layer 2: Main line */}
            <line
              x1="0" y1="12" x2="24" y2="12"
              stroke="#00dd77"
              strokeWidth="5"
              strokeLinecap="round"
            />

            {/* Layer 3: Energy flow slow */}
            <line
              x1="0" y1="12" x2="24" y2="12"
              stroke="#88ffcc"
              strokeWidth="3"
              strokeLinecap="round"
              strokeDasharray="6 30"
              className="level-connector-energy-slow"
            />

            {/* Layer 4: Energy flow fast */}
            <line
              x1="0" y1="12" x2="24" y2="12"
              stroke="white"
              strokeWidth="2"
              strokeLinecap="round"
              strokeDasharray="4 20"
              className="level-connector-energy-fast"
            />

            {/* Layer 5: Bright core */}
            <line
              x1="0" y1="12" x2="24" y2="12"
              stroke="#aaffcc"
              strokeWidth="1.5"
              strokeLinecap="round"
            />

            <defs>
              <filter id="connectorGlowFilter" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="2" result="coloredBlur" />
                <feMerge>
                  <feMergeNode in="coloredBlur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
            </defs>
          </>
        ) : (
          <line
            x1="0" y1="12" x2="24" y2="12"
            stroke={isActive ? "#00dd77" : "#3d3428"}
            strokeWidth="4"
            strokeLinecap="round"
          />
        )}
      </svg>
    </div>
  );
}
