/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: {
          dark: '#0f0f23',
          mid: '#1a1a3e',
          light: '#252550',
        },
        accent: {
          primary: '#22c55e',
          secondary: '#e94560',
          tertiary: '#fbbf24',
        },
        circuit: {
          cell: {
            normal: '#3a3a4a',
            edge: '#1a1a25',
          },
          start: '#15803d',
          finish: '#ca8a04',
          current: '#0d9488',
          visited: '#1a5c38',
          connector: {
            default: '#3d3428',
            active: '#00dd77',
            glow: '#00ff88',
          },
        },
        text: {
          primary: '#ffffff',
          secondary: '#a1a1aa',
        },
        error: '#ef4444',
        hearts: {
          active: '#ff3366',
          inactive: '#2a2a3a',
        },
      },
      fontFamily: {
        display: ['Nunito', 'Quicksand', 'sans-serif'],
        body: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'pulse-glow': 'pulse-glow 1.5s ease-in-out infinite',
        'electric-flow': 'electric-flow 0.8s linear infinite',
        'electric-flow-slow': 'electric-flow 1.2s linear infinite',
        'twinkle': 'twinkle 2s ease-in-out infinite',
        'heart-pulse': 'heart-pulse 1s ease-in-out infinite',
        'slide-up': 'slide-up 0.3s ease-out',
        'fade-in': 'fade-in 0.2s ease-out',
        'bounce-slow': 'bounce-slow 2s ease-in-out infinite',
        'shake': 'shake 0.3s ease-in-out',
        'slide-in-left': 'slide-in-left 0.2s ease-out',
      },
      keyframes: {
        'pulse-glow': {
          '0%, 100%': {
            opacity: '1',
            transform: 'scale(1)',
          },
          '50%': {
            opacity: '0.8',
            transform: 'scale(1.02)',
          },
        },
        'electric-flow': {
          '0%': {
            strokeDashoffset: '40',
          },
          '100%': {
            strokeDashoffset: '0',
          },
        },
        'twinkle': {
          '0%, 100%': {
            opacity: '1',
            transform: 'scale(1)',
          },
          '50%': {
            opacity: '0.6',
            transform: 'scale(0.95)',
          },
        },
        'heart-pulse': {
          '0%, 100%': {
            transform: 'scale(1)',
          },
          '50%': {
            transform: 'scale(1.15)',
          },
        },
        'slide-up': {
          '0%': {
            opacity: '0',
            transform: 'translateY(20px)',
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)',
          },
        },
        'fade-in': {
          '0%': {
            opacity: '0',
          },
          '100%': {
            opacity: '1',
          },
        },
        'bounce-slow': {
          '0%, 100%': {
            transform: 'translateY(0)',
          },
          '50%': {
            transform: 'translateY(-10px)',
          },
        },
        'shake': {
          '0%, 100%': {
            transform: 'translateX(0)',
          },
          '25%': {
            transform: 'translateX(-5px)',
          },
          '75%': {
            transform: 'translateX(5px)',
          },
        },
        'slide-in-left': {
          '0%': {
            opacity: '0',
            transform: 'translateX(-100%)',
          },
          '100%': {
            opacity: '1',
            transform: 'translateX(0)',
          },
        },
      },
    },
  },
  plugins: [],
}
