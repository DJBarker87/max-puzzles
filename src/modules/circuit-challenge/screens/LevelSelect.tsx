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
 * Level selection screen with hexagon tiles for a chapter
 * Shows 5 levels (A-E) with stars and unlock status
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

  const isHiddenMode = (level: number): boolean => {
    return level === 5 || chapter === 10;
  };

  const totalStars = getStarsInChapter(chapter, progress);
  const completedLevels = [1, 2, 3, 4, 5].filter((l) =>
    isLevelCompleted(chapter, l, progress)
  ).length;

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      <Header showMenu className="relative z-10" />

      {/* Chapter header */}
      <div className="flex items-center gap-4 px-6 py-4 relative z-10">
        <img
          src={alien.imagePath}
          alt={alien.name}
          className="w-16 h-16 object-contain"
        />
        <div>
          <h1 className="text-2xl font-bold text-white">{alien.name}</h1>
          <p className="text-sm text-accent-primary/80">
            {alien.words.join(" • ")}
          </p>
        </div>
      </div>

      {/* Level path */}
      <div className="flex-1 flex flex-col items-center py-6 relative z-10">
        {[1, 2, 3, 4, 5].map((level) => (
          <div key={level} className="flex flex-col items-center">
            {/* Connector (except for level 1) */}
            {level > 1 && (
              <LevelConnector
                isActive={isLevelUnlocked(level)}
                isPulsing={isLevelCompleted(chapter, level - 1, progress)}
              />
            )}

            {/* Hexagon level tile */}
            <LevelHexTile
              level={level}
              chapter={chapter}
              isUnlocked={isLevelUnlocked(level)}
              isCompleted={isLevelCompleted(chapter, level, progress)}
              stars={getStarsForLevel(chapter, level, progress)}
              isHiddenMode={isHiddenMode(level)}
              onClick={() => handleLevelClick(level)}
            />
          </div>
        ))}
      </div>

      {/* Chapter stats */}
      <div className="text-center pb-8 relative z-10">
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

// MARK: - Level Hex Tile

interface LevelHexTileProps {
  level: number;
  chapter: number;
  isUnlocked: boolean;
  isCompleted: boolean;
  stars: number;
  isHiddenMode: boolean;
  onClick: () => void;
}

function LevelHexTile({
  level,
  isUnlocked,
  isCompleted,
  stars,
  isHiddenMode,
  onClick,
}: LevelHexTileProps) {
  return (
    <button
      onClick={onClick}
      disabled={!isUnlocked}
      className="flex flex-col items-center gap-2"
    >
      {/* Hexagon */}
      <div className="relative">
        {/* Pulsing glow for completed */}
        {isCompleted && (
          <>
            <div
              className="absolute inset-0 animate-pulse"
              style={{
                background: "radial-gradient(circle, rgba(0,255,136,0.3) 0%, transparent 70%)",
                transform: "scale(1.5)",
              }}
            />
            {/* Energy border - uses CSS animation */}
            <svg
              className="absolute -inset-1 w-[88px] h-[88px]"
              viewBox="0 0 100 100"
            >
              <polygon
                points="50,3 95,25 95,75 50,97 5,75 5,25"
                fill="none"
                stroke="#00ff88"
                strokeWidth="3"
                strokeDasharray="8 12"
                className="animate-[dash_1.5s_linear_infinite]"
              />
            </svg>
          </>
        )}

        {/* Main hexagon */}
        <svg className="w-20 h-20" viewBox="0 0 100 100">
          <defs>
            <linearGradient id={`hex-grad-${level}-${isCompleted}`} x1="0%" y1="0%" x2="100%" y2="100%">
              {isCompleted ? (
                <>
                  <stop offset="0%" stopColor="#22c55e" />
                  <stop offset="100%" stopColor="#22c55e" stopOpacity="0.7" />
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
          </defs>
          <polygon
            points="50,5 93,27 93,73 50,95 7,73 7,27"
            fill={`url(#hex-grad-${level}-${isCompleted})`}
            stroke={
              isCompleted
                ? "#00ff88"
                : isUnlocked
                ? "rgba(34,197,94,0.5)"
                : "rgba(107,114,128,0.3)"
            }
            strokeWidth="2"
          />
        </svg>

        {/* Level number or lock */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {isUnlocked ? (
            <>
              <span className="text-2xl font-bold text-white">{level}</span>
              {isHiddenMode && (
                <span className="text-xs text-accent-secondary">👁️</span>
              )}
            </>
          ) : (
            <span className="text-2xl text-gray-500">🔒</span>
          )}
        </div>
      </div>

      {/* Stars display */}
      {isCompleted ? (
        <StarDisplay stars={stars} size="small" />
      ) : isUnlocked ? (
        <StarDisplay stars={0} size="small" />
      ) : (
        <span className="text-xs text-gray-500">Need ⭐⭐</span>
      )}
    </button>
  );
}

// MARK: - Level Connector

interface LevelConnectorProps {
  isActive: boolean;
  isPulsing: boolean;
}

function LevelConnector({ isActive, isPulsing }: LevelConnectorProps) {
  return (
    <div className="relative w-1.5 h-10">
      {/* Base connector */}
      <div
        className={`absolute inset-0 rounded-full ${
          isActive ? "bg-[#00dd77]" : "bg-[#3d3428]"
        }`}
      />

      {/* Pulsing energy */}
      {isPulsing && (
        <>
          {/* Glow */}
          <div
            className="absolute inset-0 w-3 -left-0.5 rounded-full bg-[#00ff88] opacity-50 blur-sm"
          />
          {/* Energy flow animation */}
          <div
            className="absolute inset-0 w-1 left-0.25 bg-gradient-to-b from-transparent via-white to-transparent animate-[flowDown_0.8s_linear_infinite]"
          />
        </>
      )}
    </div>
  );
}
