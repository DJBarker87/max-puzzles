import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Header from "@/hub/components/Header";
import { StarryBackground } from "../components";
import { StarDisplay } from "../components/StarReveal";
import { chapterAliens } from "@/shared/types/chapterAlien";
import {
  getStoryProgress,
  isChapterUnlocked,
  isLevelCompleted,
  getStarsForLevel,
  getStarsInChapter,
  type StoryProgressData,
} from "@/shared/types/storyProgress";

/**
 * Level selection screen with large horizontal hexagon tiles
 * Current level has green glow pulse animation
 */
export default function LevelSelect() {
  const navigate = useNavigate();
  const { chapterId } = useParams<{ chapterId: string }>();
  const chapter = parseInt(chapterId || "1", 10);

  const [progress, setProgress] = useState<StoryProgressData>({
    levelProgress: {},
  });

  const alien = chapterAliens.find((a) => a.chapter === chapter);

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

  // Level n+1 unlocks when 2+ stars on level n
  const isLevelUnlocked = (level: number): boolean => {
    if (!isChapterUnlocked(chapter, progress)) return false;
    if (level === 1) return true;
    return getStarsForLevel(chapter, level - 1, progress) >= 2;
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
      <StarryBackground />

      <Header showMenu className="relative z-10 shrink-0" />

      {/* Chapter header */}
      <div className="flex items-center gap-4 px-6 py-4 relative z-10 shrink-0">
        <img
          src={alien.imagePath}
          alt={alien.name}
          className="w-14 h-14 object-contain"
        />
        <div>
          <h1 className="text-xl font-bold text-white">{alien.name}</h1>
          <p className="text-xs text-accent-primary/80">
            {alien.words.join(" • ")}
          </p>
        </div>
      </div>

      {/* Horizontal level path */}
      <div className="flex-1 flex items-center justify-center relative z-10 overflow-x-auto px-4">
        <div className="flex items-center gap-0 py-8">
          {[1, 2, 3, 4, 5].map((level) => (
            <div key={level} className="flex items-center">
              {/* Hexagon level tile */}
              <LargeHexTile
                level={level}
                chapter={chapter}
                isUnlocked={isLevelUnlocked(level)}
                isCompleted={isLevelCompleted(chapter, level, progress)}
                isCurrent={isCurrentLevel(level)}
                stars={getStarsForLevel(chapter, level, progress)}
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
  isHiddenMode: boolean;
  onClick: () => void;
}

function LargeHexTile({
  level,
  isUnlocked,
  isCompleted,
  isCurrent,
  stars,
  isHiddenMode,
  onClick,
}: LargeHexTileProps) {
  const shouldPulse = isCurrent || isCompleted;
  const hexSize = 90; // Larger hexagons

  return (
    <button
      onClick={onClick}
      disabled={!isUnlocked}
      className="flex flex-col items-center gap-3"
    >
      {/* Hexagon */}
      <div className="relative" style={{ width: hexSize + 40, height: hexSize + 40 }}>
        {/* Pulsing glow for current/completed */}
        {shouldPulse && (
          <>
            {/* Outer glow */}
            <div
              className="absolute inset-0 animate-pulse"
              style={{
                background: "radial-gradient(circle, rgba(0,255,136,0.4) 0%, transparent 60%)",
              }}
            />
            {/* Inner glow */}
            <div
              className="absolute"
              style={{
                top: 10,
                left: 10,
                right: 10,
                bottom: 10,
                background: "radial-gradient(circle, rgba(0,255,136,0.3) 0%, transparent 70%)",
                filter: "blur(8px)",
              }}
            />
            {/* Energy border animation */}
            <svg
              className="absolute inset-0"
              style={{ width: hexSize + 40, height: hexSize + 40 }}
              viewBox="0 0 130 130"
            >
              <polygon
                points="65,8 118,35 118,95 65,122 12,95 12,35"
                fill="none"
                stroke="#00ff88"
                strokeWidth="4"
                strokeDasharray="10 15"
                className="animate-[dash_1.2s_linear_infinite]"
              />
              <polygon
                points="65,8 118,35 118,95 65,122 12,95 12,35"
                fill="none"
                stroke="white"
                strokeWidth="2"
                strokeDasharray="5 20"
                strokeOpacity="0.8"
                className="animate-[dash_0.8s_linear_infinite]"
              />
            </svg>
          </>
        )}

        {/* Main hexagon */}
        <svg
          className="absolute"
          style={{
            width: hexSize,
            height: hexSize,
            top: 20,
            left: 20,
          }}
          viewBox="0 0 100 100"
        >
          <defs>
            <linearGradient id={`hex-grad-${level}-${isCompleted}-${isCurrent}`} x1="0%" y1="0%" x2="100%" y2="100%">
              {isCompleted ? (
                <>
                  <stop offset="0%" stopColor="#22c55e" />
                  <stop offset="100%" stopColor="#22c55e" stopOpacity="0.7" />
                </>
              ) : isCurrent ? (
                <>
                  <stop offset="0%" stopColor="#0d9488" />
                  <stop offset="100%" stopColor="#086560" />
                </>
              ) : isUnlocked ? (
                <>
                  <stop offset="0%" stopColor="#1a1a3e" />
                  <stop offset="100%" stopColor="#0f0f23" />
                </>
              ) : (
                <>
                  <stop offset="0%" stopColor="#374151" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#374151" stopOpacity="0.2" />
                </>
              )}
            </linearGradient>
            {shouldPulse && (
              <filter id={`glow-${level}`}>
                <feGaussianBlur stdDeviation="3" result="coloredBlur" />
                <feMerge>
                  <feMergeNode in="coloredBlur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
            )}
          </defs>
          <polygon
            points="50,5 93,27 93,73 50,95 7,73 7,27"
            fill={`url(#hex-grad-${level}-${isCompleted}-${isCurrent})`}
            stroke={
              shouldPulse
                ? "#00ff88"
                : isUnlocked
                ? "rgba(34,197,94,0.5)"
                : "rgba(107,114,128,0.3)"
            }
            strokeWidth={shouldPulse ? "3" : "2"}
            filter={shouldPulse ? `url(#glow-${level})` : undefined}
          />
        </svg>

        {/* Level number or lock */}
        <div
          className="absolute flex flex-col items-center justify-center"
          style={{
            top: 20,
            left: 20,
            width: hexSize,
            height: hexSize,
          }}
        >
          {isUnlocked ? (
            <>
              <span className="text-4xl font-bold text-white">{level}</span>
              {isHiddenMode && (
                <span className="text-xs text-accent-secondary mt-1">👁️</span>
              )}
            </>
          ) : (
            <span className="text-3xl text-gray-500">🔒</span>
          )}
        </div>
      </div>

      {/* Stars display */}
      {isCompleted ? (
        <StarDisplay stars={stars} size="medium" />
      ) : isUnlocked ? (
        <StarDisplay stars={0} size="medium" />
      ) : (
        <span className="text-xs text-gray-500">Need ⭐⭐</span>
      )}
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
    <div className="relative h-6 w-8 flex items-center">
      {/* Base connector */}
      <div
        className={`absolute h-1.5 w-full rounded-full ${
          isActive ? "bg-[#00dd77]" : "bg-[#3d3428]"
        }`}
      />

      {/* Pulsing energy */}
      {isPulsing && (
        <>
          {/* Glow */}
          <div className="absolute h-3 w-full rounded-full bg-[#00ff88] opacity-50 blur-sm" />
          {/* Energy flow animation */}
          <div
            className="absolute h-1 w-full overflow-hidden"
            style={{ top: "calc(50% - 2px)" }}
          >
            <div
              className="h-full w-1/3 bg-gradient-to-r from-transparent via-white to-transparent animate-[flowRight_0.8s_linear_infinite]"
            />
          </div>
        </>
      )}
    </div>
  );
}
