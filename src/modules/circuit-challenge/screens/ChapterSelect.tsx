import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
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
 * Chapter selection screen with horizontal scrolling aliens
 */
export default function ChapterSelect() {
  const navigate = useNavigate();
  const [progress, setProgress] = useState<StoryProgressData>({ levelProgress: {} });

  useEffect(() => {
    setProgress(getStoryProgress());
  }, []);

  const handleChapterClick = (alien: ChapterAlien) => {
    if (isChapterUnlocked(alien.chapter, progress)) {
      navigate(`/play/circuit-challenge/story/${alien.chapter}`);
    }
  };

  const completedCount = countCompletedChapters(progress);

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      <Header showMenu className="relative z-10" />

      {/* Title */}
      <div className="text-center py-6 relative z-10">
        <h1 className="text-3xl md:text-4xl font-display font-bold text-white">
          Story Mode
        </h1>
        <p className="text-text-secondary mt-2">
          Help the aliens by solving puzzles!
        </p>
      </div>

      {/* Horizontal chapter scroll */}
      <div className="flex-1 relative z-10 overflow-hidden">
        <div className="overflow-x-auto pb-4 scrollbar-hide">
          <div className="flex gap-5 px-6 py-4 min-w-min">
            {chapterAliens.map((alien) => (
              <ChapterCard
                key={alien.id}
                alien={alien}
                isUnlocked={isChapterUnlocked(alien.chapter, progress)}
                isCompleted={isChapterCompleted(alien.chapter, progress)}
                onClick={() => handleChapterClick(alien)}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Progress indicator */}
      <div className="relative z-10 pb-8">
        <div className="flex justify-center gap-2 mb-3">
          {Array.from({ length: 10 }, (_, i) => i + 1).map((chapter) => (
            <div
              key={chapter}
              className={`w-3 h-3 rounded-full border-2 ${
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

// MARK: - Chapter Card

interface ChapterCardProps {
  alien: ChapterAlien;
  isUnlocked: boolean;
  isCompleted: boolean;
  onClick: () => void;
}

function ChapterCard({
  alien,
  isUnlocked,
  isCompleted,
  onClick,
}: ChapterCardProps) {
  return (
    <button
      onClick={onClick}
      disabled={!isUnlocked}
      className={`
        flex-shrink-0 w-36 p-4 rounded-2xl
        transition-all duration-200
        ${isUnlocked ? "cursor-pointer hover:scale-105 active:scale-95" : "cursor-not-allowed"}
        ${isUnlocked ? "bg-background-mid/60" : "bg-gray-800/30"}
        border ${
          isCompleted
            ? "border-accent-primary border-2"
            : isUnlocked
            ? "border-accent-primary/30"
            : "border-gray-700/20"
        }
      `}
    >
      {/* Alien image container */}
      <div className="relative mx-auto w-28 h-28 mb-3">
        {/* Background circle */}
        <div
          className={`
            absolute inset-0 rounded-full
            ${isUnlocked
              ? "bg-gradient-to-br from-background-mid to-background-dark"
              : "bg-gradient-to-br from-gray-700/30 to-gray-800/20"
            }
          `}
        />

        {/* Alien image */}
        <img
          src={alien.imagePath}
          alt={alien.name}
          className={`
            relative w-full h-full object-contain p-2
            ${isUnlocked ? "" : "grayscale opacity-50"}
          `}
        />

        {/* Lock overlay */}
        {!isUnlocked && (
          <div className="absolute inset-0 rounded-full bg-black/40 flex items-center justify-center">
            <span className="text-3xl">🔒</span>
          </div>
        )}

        {/* Completion checkmark */}
        {isCompleted && (
          <div className="absolute -top-1 -right-1 w-7 h-7 bg-accent-primary rounded-full flex items-center justify-center">
            <span className="text-white text-sm font-bold">✓</span>
          </div>
        )}
      </div>

      {/* Chapter number */}
      <p
        className={`text-xs font-medium ${
          isUnlocked ? "text-text-secondary" : "text-gray-600"
        }`}
      >
        Chapter {alien.chapter}
      </p>

      {/* Alien name */}
      <p
        className={`text-lg font-bold ${
          isUnlocked ? "text-white" : "text-gray-600"
        }`}
      >
        {alien.name}
      </p>

      {/* Fun words */}
      {isUnlocked && (
        <p className="text-xs text-accent-primary/80 mt-1 truncate">
          {alien.words.join(" • ")}
        </p>
      )}
    </button>
  );
}
