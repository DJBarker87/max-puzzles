import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useSound } from "@/app/providers/SoundProvider";
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
  const { playMusic } = useSound();
  const { chapterId } = useParams<{ chapterId: string }>();
  const chapter = parseInt(chapterId || "1", 10);

  const [progress, setProgress] = useState<StoryProgressData>({
    levelProgress: {},
  });

  const alien = chapterAliens.find((a) => a.chapter === chapter);

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

  return (
    <button
      onClick={onClick}
      disabled={!isUnlocked}
      className="flex flex-col items-center gap-2 flex-1"
    >
      {/* Hexagon - responsive sizing */}
      <div className="relative w-full aspect-square max-w-[80px] md:max-w-[100px]">
        {/* Pulsing glow for current/completed */}
        {shouldPulse && (
          <>
            {/* Outer glow */}
            <div
              className="absolute inset-[-15%] animate-pulse"
              style={{
                background: "radial-gradient(circle, rgba(0,255,136,0.4) 0%, transparent 60%)",
              }}
            />
            {/* Inner glow */}
            <div
              className="absolute inset-[5%]"
              style={{
                background: "radial-gradient(circle, rgba(0,255,136,0.3) 0%, transparent 70%)",
                filter: "blur(8px)",
              }}
            />
            {/* Energy border animation */}
            <svg
              className="absolute inset-[-15%] w-[130%] h-[130%]"
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
          className="absolute inset-0 w-full h-full"
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
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {isUnlocked ? (
            <>
              <span className="text-2xl md:text-3xl font-bold text-white">{level}</span>
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

      {/* Stars display */}
      {isCompleted ? (
        <StarDisplay stars={stars} size="small" />
      ) : isUnlocked ? (
        <StarDisplay stars={0} size="small" />
      ) : (
        <span className="text-[10px] text-gray-500">2 stars needed</span>
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
    <div className="relative h-6 w-4 md:w-6 flex items-center shrink-0">
      {/* Base connector */}
      <div
        className={`absolute h-1 md:h-1.5 w-full rounded-full ${
          isActive ? "bg-[#00dd77]" : "bg-[#3d3428]"
        }`}
      />

      {/* Pulsing energy */}
      {isPulsing && (
        <>
          {/* Glow */}
          <div className="absolute h-2 md:h-3 w-full rounded-full bg-[#00ff88] opacity-50 blur-sm" />
          {/* Energy flow animation */}
          <div
            className="absolute h-0.5 md:h-1 w-full overflow-hidden"
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
