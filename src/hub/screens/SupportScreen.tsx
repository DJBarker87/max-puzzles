import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Header from '../components/Header'

/**
 * Support screen with FAQ and contact information
 */
export default function SupportScreen() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Support" showBack />

      <main className="flex-1 p-4 md:p-8 overflow-y-auto">
        <div className="max-w-2xl mx-auto">
          {/* Title */}
          <h1 className="text-2xl md:text-3xl font-display font-bold text-white mb-2">
            Help & Support
          </h1>
          <p className="text-text-secondary mb-8">
            Got questions? We're here to help!
          </p>

          {/* FAQ Section */}
          <section className="mb-10">
            <h2 className="text-xl font-display font-bold text-white mb-4 pb-2 border-b border-background-light/30">
              Frequently Asked Questions
            </h2>

            <div className="space-y-3">
              <FAQItem question="How do I play Circuit Challenge?">
                Tap on hexagons next to your current position to move through the puzzle.
                Each hexagon shows a maths problem - solve it and find the connector that
                matches your answer to move forward. Get from START to FINISH to win!
              </FAQItem>

              <FAQItem question="What do the different game modes do?">
                <strong className="text-white">Quick Play</strong> lets you jump straight into puzzles at any difficulty level.
                <br /><br />
                <strong className="text-white">Story Mode</strong> takes you on an adventure with friendly alien characters,
                progressing through chapters as you complete levels.
                <br /><br />
                <strong className="text-white">Puzzle Maker</strong> lets you print puzzle worksheets to solve on paper -
                great for classrooms or offline practice!
              </FAQItem>

              <FAQItem question="What is Hidden Mode?">
                Hidden Mode is an extra challenge! You won't see if your answers are right
                or wrong until the end. There are no lives in Hidden Mode - just solve the
                puzzle and see how you did at the finish.
              </FAQItem>

              <FAQItem question="How do lives work?">
                In standard mode, you start with 5 lives (hearts). Each wrong answer costs
                one life. If you run out of lives, the game ends. Don't worry - you can
                always try again!
              </FAQItem>

              <FAQItem question="Can I play offline?">
                Yes! The app works completely offline. Your progress is saved on your device,
                so you can play anywhere without an internet connection.
              </FAQItem>

              <FAQItem question="How do I reset my progress?">
                You can clear all your saved data in the Settings menu. Look for the
                "Clear All Data" option. This will reset all your progress and start fresh.
              </FAQItem>

              <FAQItem question="Is this app safe for children?">
                Absolutely! We designed this app with children's safety as a top priority.
                We don't collect any personal information, there are no ads, no in-app
                purchases, and no external links. See our Privacy Policy for full details.
              </FAQItem>

              <FAQItem question="What ages is this app for?">
                Maxi's Mighty Mindgames is designed for children aged 5-11. The difficulty
                levels range from simple addition for younger children to more complex
                mixed operations for older players.
              </FAQItem>
            </div>
          </section>

          {/* Contact Section */}
          <section className="mb-10">
            <h2 className="text-xl font-display font-bold text-white mb-4 pb-2 border-b border-background-light/30">
              Contact Us
            </h2>

            <div className="bg-background-mid rounded-lg p-5">
              <p className="text-text-secondary mb-4">
                Can't find what you're looking for? Have a suggestion or found a bug?
                We'd love to hear from you!
              </p>

              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <span className="text-2xl">📧</span>
                  <div>
                    <p className="text-text-secondary text-sm">Email</p>
                    <a
                      href="mailto:dombarker@gmail.com"
                      className="text-accent-primary hover:underline font-semibold"
                    >
                      dombarker@gmail.com
                    </a>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span className="text-2xl">👨‍💻</span>
                  <div>
                    <p className="text-text-secondary text-sm">Developer</p>
                    <p className="text-white font-semibold">Dominic Barker</p>
                  </div>
                </div>
              </div>

              <p className="text-text-secondary text-sm mt-4 pt-4 border-t border-background-light/20">
                We typically respond within 24-48 hours.
              </p>
            </div>
          </section>

          {/* Troubleshooting Section */}
          <section className="mb-10">
            <h2 className="text-xl font-display font-bold text-white mb-4 pb-2 border-b border-background-light/30">
              Troubleshooting
            </h2>

            <div className="space-y-4 text-text-secondary">
              <div className="bg-background-mid rounded-lg p-4">
                <h3 className="text-white font-semibold mb-2">App not loading properly?</h3>
                <p>Try closing and reopening the app. If the problem persists,
                check for app updates in the App Store.</p>
              </div>

              <div className="bg-background-mid rounded-lg p-4">
                <h3 className="text-white font-semibold mb-2">Progress not saving?</h3>
                <p>Make sure you don't have "Private Browsing" enabled if using the web version.
                Progress is saved locally on your device.</p>
              </div>

              <div className="bg-background-mid rounded-lg p-4">
                <h3 className="text-white font-semibold mb-2">Sound not working?</h3>
                <p>Check that your device isn't on silent mode and that sound is enabled
                in the app's Settings menu.</p>
              </div>
            </div>
          </section>

          {/* Quick Links */}
          <section className="mb-8">
            <h2 className="text-xl font-display font-bold text-white mb-4 pb-2 border-b border-background-light/30">
              Quick Links
            </h2>

            <div className="flex flex-wrap gap-3">
              <button
                onClick={() => navigate('/privacy')}
                className="px-4 py-2 bg-background-mid rounded-lg text-text-secondary hover:text-white transition-colors"
              >
                Privacy Policy
              </button>
              <button
                onClick={() => navigate('/settings')}
                className="px-4 py-2 bg-background-mid rounded-lg text-text-secondary hover:text-white transition-colors"
              >
                Settings
              </button>
              <button
                onClick={() => navigate('/play/circuit-challenge')}
                className="px-4 py-2 bg-background-mid rounded-lg text-text-secondary hover:text-white transition-colors"
              >
                Play Now
              </button>
            </div>
          </section>

          {/* Back button */}
          <div className="mt-8 mb-8 text-center">
            <button
              onClick={() => navigate(-1)}
              className="text-accent-primary hover:underline font-semibold"
            >
              ← Back to App
            </button>
          </div>
        </div>
      </main>
    </div>
  )
}

/**
 * Collapsible FAQ item component
 */
function FAQItem({ question, children }: { question: string; children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="bg-background-mid rounded-lg overflow-hidden">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full p-4 text-left flex items-center justify-between gap-4 hover:bg-background-light/10 transition-colors"
      >
        <span className="text-white font-semibold">{question}</span>
        <span className={`text-accent-primary transition-transform ${isOpen ? 'rotate-180' : ''}`}>
          ▼
        </span>
      </button>
      {isOpen && (
        <div className="px-4 pb-4 text-text-secondary">
          {children}
        </div>
      )}
    </div>
  )
}
