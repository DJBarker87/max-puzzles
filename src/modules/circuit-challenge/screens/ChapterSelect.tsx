import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { useSound } from "@/app/providers/SoundProvider";
import Header from "@/hub/components/Header";
import { StarryBackground } from "../components";
import {
  chapterAliens,
  type ChapterAlien,
} from "@/shared/types/chapterAlien";
import {
  getStoryProgress,
  isChapterUnlocked,
  isChapterCompleted,
  type StoryProgressData,
} from "@/shared/types/storyProgress";

/** Count completed chapters */
function countCompletedChapters(progress: StoryProgressData): number {
  let count = 0;
  for (let chapter = 1; chapter <= 10; chapter++) {
    if (isChapterCompleted(chapter, progress)) {
      count++;
    }
  }
  return count;
}

/**
 * Chapter selection screen with 3D carousel of large alien cards
 */
export default function ChapterSelect() {
  const navigate = useNavigate();
  const { playMusic } = useSound();
  const [progress, setProgress] = useState<StoryProgressData>({ levelProgress: {} });
  const [currentIndex, setCurrentIndex] = useState(0);
  const [dragStart, setDragStart] = useState<number | null>(null);
  const [dragOffset, setDragOffset] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  // Continue hub music on this screen
  useEffect(() => {
    playMusic("hub", true);
  }, [playMusic]);

  useEffect(() => {
    setProgress(getStoryProgress());
  }, []);

  const handleChapterClick = (alien: ChapterAlien, index: number) => {
    if (index === currentIndex && isChapterUnlocked(alien.chapter, progress)) {
      navigate(`/play/circuit-challenge/story/${alien.chapter}`);
    } else {
      setCurrentIndex(index);
    }
  };

  const handleDragStart = (clientX: number) => {
    setDragStart(clientX);
  };

  const handleDragMove = (clientX: number) => {
    if (dragStart !== null) {
      setDragOffset(clientX - dragStart);
    }
  };

  const handleDragEnd = () => {
    if (dragStart === null) return;

    const threshold = 80;
    if (dragOffset < -threshold && currentIndex < chapterAliens.length - 1) {
      setCurrentIndex(currentIndex + 1);
    } else if (dragOffset > threshold && currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }

    setDragStart(null);
    setDragOffset(0);
  };

  const completedCount = countCompletedChapters(progress);

  return (
    <div className="h-screen flex flex-col relative overflow-hidden">
      <StarryBackground />

      <Header showMenu className="relative z-10 shrink-0" />

      {/* Title */}
      <div className="text-center py-4 relative z-10 shrink-0">
        <h1 className="text-2xl md:text-3xl font-display font-bold text-white">
          Story Mode
        </h1>
        <p className="text-text-secondary text-sm mt-1">
          Help the aliens by solving puzzles!
        </p>
      </div>

      {/* 3D Carousel */}
      <div
        ref={containerRef}
        className="flex-1 relative z-10 flex items-center justify-center overflow-hidden touch-pan-y"
        onMouseDown={(e) => handleDragStart(e.clientX)}
        onMouseMove={(e) => handleDragMove(e.clientX)}
        onMouseUp={handleDragEnd}
        onMouseLeave={handleDragEnd}
        onTouchStart={(e) => handleDragStart(e.touches[0].clientX)}
        onTouchMove={(e) => handleDragMove(e.touches[0].clientX)}
        onTouchEnd={handleDragEnd}
      >
        <div className="relative w-full h-full flex items-center justify-center">
          {chapterAliens.map((alien, index) => {
            const offset = index - currentIndex + (dragOffset / 300);
            const absOffset = Math.abs(offset);

            // 3D transforms for sphere effect
            const angle = offset * 35;
            const scale = Math.max(0.6, 1 - absOffset * 0.15);
            const xOffset = offset * 120;
            const opacity = Math.max(0.3, 1 - absOffset * 0.3);
            const zIndex = 10 - Math.round(absOffset);

            return (
              <LargeChapterCard
                key={alien.id}
                alien={alien}
                isUnlocked={isChapterUnlocked(alien.chapter, progress)}
                isCompleted={isChapterCompleted(alien.chapter, progress)}
                isCurrent={index === currentIndex}
                onClick={() => handleChapterClick(alien, index)}
                style={{
                  position: "absolute",
                  transform: `translateX(${xOffset}px) scale(${scale}) rotateY(${angle}deg)`,
                  opacity,
                  zIndex,
                  transition: dragStart === null ? "all 0.4s cubic-bezier(0.4, 0, 0.2, 1)" : "none",
                }}
              />
            );
          })}
        </div>
      </div>

      {/* Progress indicator */}
      <div className="relative z-10 pb-6 shrink-0">
        <div className="flex justify-center gap-2 mb-3">
          {Array.from({ length: 10 }, (_, i) => i + 1).map((chapter) => (
            <div
              key={chapter}
              className={`rounded-full border-2 transition-all duration-300 ${
                currentIndex === chapter - 1 ? "w-3.5 h-3.5" : "w-2.5 h-2.5"
              } ${
                isChapterCompleted(chapter, progress)
                  ? "bg-accent-primary border-accent-primary"
                  : isChapterUnlocked(chapter, progress)
                  ? "bg-background-mid border-accent-primary/50"
                  : "bg-gray-700/30 border-gray-700/30"
              }`}
            />
          ))}
        </div>
        <p className="text-center text-text-secondary text-sm">
          {completedCount} of 10 chapters completed
        </p>
      </div>
    </div>
  );
}

// MARK: - Large Chapter Card

interface LargeChapterCardProps {
  alien: ChapterAlien;
  isUnlocked: boolean;
  isCompleted: boolean;
  isCurrent: boolean;
  onClick: () => void;
  style?: React.CSSProperties;
}

function LargeChapterCard({
  alien,
  isUnlocked,
  isCompleted,
  isCurrent,
  onClick,
  style,
}: LargeChapterCardProps) {
  return (
    <button
      onClick={onClick}
      className={`
        w-[70vw] max-w-[280px] h-[60vh] max-h-[450px]
        flex flex-col items-center justify-between
        rounded-3xl p-6
        ${isUnlocked ? "cursor-pointer" : "cursor-default"}
        bg-gradient-to-b ${
          isUnlocked
            ? "from-background-mid/90 to-background-dark/95"
            : "from-gray-800/50 to-gray-900/50"
        }
        border-2 ${
          isCompleted
            ? "border-accent-primary"
            : isCurrent && isUnlocked
            ? "border-accent-primary"
            : isUnlocked
            ? "border-accent-primary/40"
            : "border-gray-700/20"
        }
        ${isCurrent && isUnlocked ? "shadow-[0_0_30px_rgba(34,197,94,0.3)]" : "shadow-lg"}
      `}
      style={{
        ...style,
        transformStyle: "preserve-3d",
        perspective: "1000px",
      }}
    >
      <div className="flex-1" />

      {/* Alien image container */}
      <div className="relative w-full aspect-square max-w-[200px]">
        {/* Glow effect for unlocked */}
        {isUnlocked && (
          <div
            className="absolute inset-0 rounded-full opacity-50"
            style={{
              background: "radial-gradient(circle, rgba(34,197,94,0.3) 0%, transparent 70%)",
            }}
          />
        )}

        {/* Alien image */}
        <img
          src={alien.imagePath}
          alt={alien.name}
          className={`
            relative w-full h-full object-contain p-4
            ${isUnlocked ? "" : "grayscale opacity-50"}
          `}
        />

        {/* Lock overlay */}
        {!isUnlocked && (
          <div className="absolute inset-0 rounded-full bg-black/50 flex items-center justify-center">
            <span className="text-5xl">🔒</span>
          </div>
        )}

        {/* Completion checkmark */}
        {isCompleted && (
          <div
            className="absolute -top-2 -right-2 w-11 h-11 bg-accent-primary rounded-full flex items-center justify-center shadow-lg"
            style={{ boxShadow: "0 0 15px rgba(34,197,94,0.5)" }}
          >
            <span className="text-white text-xl font-bold">✓</span>
          </div>
        )}
      </div>

      <div className="flex-1" />

      {/* Chapter info */}
      <div className="text-center">
        <p
          className={`text-sm font-medium ${
            isUnlocked ? "text-text-secondary" : "text-gray-600"
          }`}
        >
          Chapter {alien.chapter}
        </p>
        <p
          className={`text-3xl font-display font-black mt-1 ${
            isUnlocked ? "text-white" : "text-gray-600"
          }`}
        >
          {alien.name}
        </p>
        {isUnlocked && (
          <p className="text-sm text-accent-primary/90 mt-2">
            {alien.words.join(" • ")}
          </p>
        )}
      </div>
    </button>
  );
}
