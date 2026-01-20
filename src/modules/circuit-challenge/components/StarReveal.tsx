import { useState, useEffect } from "react";

interface StarRevealProps {
  starsEarned: number; // 1-3
  onComplete: () => void;
}

/**
 * Animated star reveal after completing a level
 * Stars pop up and fly into their holders one by one
 */
export function StarReveal({ starsEarned, onComplete }: StarRevealProps) {
  const [revealedStars, setRevealedStars] = useState(0);
  const [animatingIndex, setAnimatingIndex] = useState(-1);

  const STAR_DELAY = 400; // ms between each star

  useEffect(() => {
    // Animate stars one by one
    for (let i = 0; i < starsEarned; i++) {
      setTimeout(() => {
        setAnimatingIndex(i);
      }, i * STAR_DELAY);

      setTimeout(() => {
        setRevealedStars(i + 1);
      }, i * STAR_DELAY + 300);
    }

    // Call completion after all stars revealed
    const totalDuration = starsEarned * STAR_DELAY + 500;
    const timer = setTimeout(onComplete, totalDuration);

    return () => clearTimeout(timer);
  }, [starsEarned, onComplete]);

  return (
    <div className="flex flex-col items-center gap-8">
      {/* Star holders */}
      <div className="flex gap-6">
        {[0, 1, 2].map((index) => (
          <StarHolder
            key={index}
            isFilled={revealedStars > index}
            isAnimating={animatingIndex === index}
          />
        ))}
      </div>

      {/* Flying stars */}
      <div className="relative h-20">
        {[0, 1, 2].map((index) =>
          index < starsEarned ? (
            <FlyingStar
              key={index}
              isActive={animatingIndex === index}
              isHidden={revealedStars > index}
            />
          ) : null
        )}
      </div>
    </div>
  );
}

interface StarHolderProps {
  isFilled: boolean;
  isAnimating: boolean;
}

function StarHolder({ isFilled, isAnimating }: StarHolderProps) {
  return (
    <div className="relative">
      {/* Glow effect */}
      {isAnimating && (
        <div className="absolute inset-0 text-6xl text-accent-tertiary blur-lg opacity-80 animate-pulse">
          ★
        </div>
      )}

      {/* Star */}
      <div
        className={`text-5xl transition-all duration-300 ${
          isFilled
            ? "text-accent-tertiary scale-110"
            : "text-text-secondary/30"
        } ${isAnimating ? "scale-125" : ""}`}
      >
        {isFilled ? "★" : "☆"}
      </div>
    </div>
  );
}

interface FlyingStarProps {
  isActive: boolean;
  isHidden: boolean;
}

function FlyingStar({ isActive, isHidden }: FlyingStarProps) {
  return (
    <div
      className={`absolute left-1/2 -translate-x-1/2 text-6xl text-accent-tertiary transition-all duration-300 ${
        isActive
          ? "opacity-100 scale-125 translate-y-0"
          : isHidden
          ? "opacity-0 scale-50 -translate-y-24"
          : "opacity-0 scale-0 translate-y-12"
      }`}
      style={{
        filter: "drop-shadow(0 0 10px rgba(251, 191, 36, 0.6))",
      }}
    >
      ★
    </div>
  );
}

// MARK: - Star Display (Static)

interface StarDisplayProps {
  stars: number; // 0-3
  maxStars?: number;
  size?: "small" | "medium" | "large";
}

export function StarDisplay({
  stars,
  maxStars = 3,
  size = "medium",
}: StarDisplayProps) {
  const sizeClasses = {
    small: "text-base gap-0.5",
    medium: "text-2xl gap-1",
    large: "text-4xl gap-2",
  };

  return (
    <div className={`flex ${sizeClasses[size]}`}>
      {Array.from({ length: maxStars }, (_, i) => (
        <span
          key={i}
          className={i < stars ? "text-accent-tertiary" : "text-text-secondary/30"}
        >
          {i < stars ? "★" : "☆"}
        </span>
      ))}
    </div>
  );
}
