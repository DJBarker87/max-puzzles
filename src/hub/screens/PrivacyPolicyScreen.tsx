import { useNavigate } from 'react-router-dom'
import Header from '../components/Header'

/**
 * Privacy Policy screen - styled markdown content
 */
export default function PrivacyPolicyScreen() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Privacy Policy" showBack />

      <main className="flex-1 p-4 md:p-8 overflow-y-auto">
        <article className="max-w-2xl mx-auto prose prose-invert">
          {/* Title */}
          <h1 className="text-2xl md:text-3xl font-display font-bold text-white mb-2">
            Privacy Policy
          </h1>
          <p className="text-accent-primary font-semibold text-lg mb-1">
            Maxi's Mighty Mindgames
          </p>
          <p className="text-text-secondary italic mb-8">
            Effective Date: January 2026
          </p>

          {/* Introduction */}
          <Section title="Introduction">
            <p>
              Maxi's Mighty Mindgames ("the App") is an educational puzzle application
              designed for children aged 5–11. This Privacy Policy explains how we handle
              information when you use the App. We are committed to protecting the privacy
              of all users, with particular attention to the safety and privacy of children.
            </p>
            <p>
              We have designed this App with a privacy-first approach. We do not collect,
              store, transmit, or share any personal information from any user, including children.
            </p>
          </Section>

          {/* Scope */}
          <Section title="Scope of This Policy">
            <p>
              This Privacy Policy applies to the Maxi's Mighty Mindgames mobile application
              available on the Apple App Store. By downloading, installing, or using the App,
              you agree to the terms of this Privacy Policy.
            </p>
          </Section>

          {/* Information We Collect */}
          <Section title="Information We Collect">
            <h3 className="text-lg font-semibold text-white mt-4 mb-2">Personal Information</h3>
            <p>
              <strong className="text-accent-primary">We do not collect any personal information.</strong>{' '}
              The App does not request, require, or transmit any personally identifiable information,
              including but not limited to: names, email addresses, physical addresses, telephone numbers,
              photographs, location data, device identifiers, or any other information that could be
              used to identify or contact a user.
            </p>

            <h3 className="text-lg font-semibold text-white mt-4 mb-2">Locally Stored Data</h3>
            <p>
              The App stores limited non-personal data locally on the user's device to enable
              core functionality. This data includes:
            </p>
            <ul className="list-disc list-inside space-y-1 text-text-secondary ml-2">
              <li>Game progress and achievement records</li>
              <li>High scores and performance statistics</li>
              <li>Optional display name (entered by the user, stored locally only)</li>
              <li>Sound and music preferences</li>
              <li>Difficulty and gameplay settings</li>
            </ul>
            <p className="mt-3 italic text-text-secondary">
              This data is stored exclusively on the user's device and is never transmitted
              to our servers or any third party. Users may delete all locally stored data at
              any time via the Settings menu by selecting "Clear All Data."
            </p>
          </Section>

          {/* What We Do Not Do */}
          <Section title="Data Practices: What We Do Not Do">
            <p>
              To ensure the highest standards of privacy protection, the App is designed
              with the following restrictions:
            </p>
            <ul className="space-y-2 mt-3">
              <ListItem label="No Personal Data Collection">
                We do not collect, process, or store personal information of any kind.
              </ListItem>
              <ListItem label="No Analytics or Tracking">
                We do not use analytics services, cookies, pixels, or any tracking technologies.
              </ListItem>
              <ListItem label="No Advertisements">
                The App contains no advertising of any kind, including behavioural or contextual advertisements.
              </ListItem>
              <ListItem label="No Third-Party Data Sharing">
                We do not share, sell, rent, or disclose any data to third parties.
              </ListItem>
              <ListItem label="No Account Registration">
                The App does not require or offer account creation.
              </ListItem>
              <ListItem label="No In-App Purchases">
                The App contains no in-app purchases or payment mechanisms.
              </ListItem>
              <ListItem label="No External Links">
                The App does not contain links to external websites, social media platforms, or other applications.
              </ListItem>
            </ul>
          </Section>

          {/* Children's Privacy */}
          <Section title="Children's Privacy and COPPA Compliance">
            <p>
              This App complies with the Children's Online Privacy Protection Act (COPPA),
              the General Data Protection Regulation (GDPR) provisions concerning children,
              and Apple's App Store Guidelines for apps in the Kids Category.
            </p>
            <p>
              Because the App does not collect any personal information from any user,
              including children under the age of 13 (or the applicable age in your jurisdiction),
              no verifiable parental consent is required to use this App.
            </p>
            <p>
              The App is designed to be fully functional without network connectivity,
              ensuring that no data transmission occurs during use.
            </p>
          </Section>

          {/* Data Security */}
          <Section title="Data Security">
            <p>
              Because all data is stored locally on the user's device and is never transmitted
              over any network, the data is protected by the security measures inherent to the
              user's device and operating system. We do not maintain servers that store user data.
            </p>
          </Section>

          {/* Changes */}
          <Section title="Changes to This Privacy Policy">
            <p>
              We may update this Privacy Policy from time to time. Any changes will be reflected
              by updating the "Effective Date" at the top of this document. If we make material
              changes to this Privacy Policy, we will notify users through an update to the App.
              Continued use of the App following any changes constitutes acceptance of the revised
              Privacy Policy.
            </p>
          </Section>

          {/* Contact */}
          <Section title="Contact Information">
            <p>
              If you have any questions, concerns, or requests regarding this Privacy Policy
              or the App's privacy practices, please contact us at:
            </p>
            <div className="mt-3 p-4 bg-background-mid rounded-lg">
              <p className="text-white">
                <strong>Email:</strong>{' '}
                <a
                  href="mailto:dombarker@gmail.com"
                  className="text-accent-primary hover:underline"
                >
                  dombarker@gmail.com
                </a>
              </p>
              <p className="text-white mt-1">
                <strong>Developer:</strong> Dominic Barker
              </p>
            </div>
          </Section>

          {/* Back button at bottom */}
          <div className="mt-12 mb-8 text-center">
            <button
              onClick={() => navigate(-1)}
              className="text-accent-primary hover:underline font-semibold"
            >
              ← Back to App
            </button>
          </div>
        </article>
      </main>
    </div>
  )
}

/**
 * Section component for consistent styling
 */
function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-8">
      <h2 className="text-xl font-display font-bold text-white mb-3 pb-2 border-b border-background-light/30">
        {title}
      </h2>
      <div className="text-text-secondary space-y-3">
        {children}
      </div>
    </section>
  )
}

/**
 * List item with bold label
 */
function ListItem({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <li className="flex flex-col text-text-secondary">
      <span className="font-semibold text-white">{label}:</span>
      <span className="ml-4">{children}</span>
    </li>
  )
}
