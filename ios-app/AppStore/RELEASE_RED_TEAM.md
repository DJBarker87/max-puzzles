# App Store release red team

Reviewed: 14 July 2026

## Verdict

Version 1.2 (build 4) is fully populated in App Store Connect: the processed build is attached, both screenshot sets are complete, and the listing, categories, age rating and review information match the release payload. A final read-only API audit confirms the version remains `PREPARE_FOR_SUBMISSION` and has no review-submission resource. No submission or release action was called. Do not press Submit for Review until the manual legal/privacy confirmations and physical-device checks below are complete.

## Automated release evidence

- All 107 unit tests pass, including coverage for every supported letter and number path.
- The final serial iPhone UI run passes 11 product-flow tests and four launch configurations with zero failures.
- The iPad writing-tools UI run passes, including the visible Pencil-only control and its off/on/off state changes.
- Debug and Release simulator builds succeed for the iPhone target.
- Xcode's Release static analysis and shallow App Store bundle validation succeed.
- A generic-device archive and App Store Connect export both succeed with automatic signing.
- The exported 25.3 MB IPA is signed by `Apple Distribution: Dominic Barker (XAB7FWS6XP)` and passes strict code-signature verification.
- The exported payload is `com.maxpuzzles.app`, version 1.2, build 4, with iOS 16.0 minimum, `ITSAppUsesNonExemptEncryption = false`, the privacy manifest and opaque iPhone/iPad icons.
- Xcode uploaded build 4 successfully; Apple processed it as `VALID`, and it is attached to version 1.2.
- The live record has manual release, `usesIdfa = false`, a complete private review contact, no demo account, the existing Made for Kids enrollment and the existing Free price with GBR as the base territory.
- A read-only post-sync audit confirms the only screenshot sets are the intended 6.9-inch iPhone and 13-inch iPad sets, all 16 images are `COMPLETE` and byte-match the local release files, every stored metadata value matches the payload, and no review submission exists.
- The Release app installs and launches successfully on an iPhone 17 Pro Max simulator.
- The Debug-only screenshot routing strings are absent from the Release executable.
- The built app contains its privacy manifest and the expected bundle ID, display name, version and microphone purpose string.
- Final screenshots were verified as opaque JPEGs: eight at 1320×2868 for 6.9-inch iPhone and eight at 2048×2732 for 13-inch iPad.

## Submission blockers

| Priority | Finding | Required action |
| --- | --- | --- |
| Resolved | A public privacy policy is live at `https://maxis-mighty-mindgames-support.vercel.app/privacy`. | Entered into the prepared metadata payload. |
| Resolved | A public support page with the product's existing contact details is live at `https://maxis-mighty-mindgames-support.vercel.app/support`. | Entered into the prepared metadata payload. |
| Resolved | Apple's public listing confirms version 1.1 is live, with a 4+ rating, Data Not Collected and recommended age 6–8. | The new release was advanced to version 1.2 build 4; retain the existing truthful Kids and privacy selections. |
| Resolved | The signed version 1.2 build 4 package needed to reach App Store Connect. | Upload, processing and version attachment all succeeded. |
| Resolved | The listing, screenshot sets, categories, Kids band, age rating and review details needed to be populated. | The authenticated sync completed and the independent read-only audit matches every prepared value. |
| P0 | DSA trader status and any additional App Store Connect agreements are account-level legal declarations that cannot be derived from the app. | Confirm the truthful account-level selections before submission. |
| P0 | App privacy and content-rights provenance cannot be safely inferred or fully written through the current API. | Retain the existing Data Not Collected answer, confirm asset rights and visually verify both before submission. The existing content-rights declaration and review contact are present. |
| P1 | Simulator testing cannot validate a real Apple Pencil, microphone hardware, real memory pressure or install-from-TestFlight behaviour. | Run build 4 through TestFlight on a supported iPhone and a Pencil-capable iPad before submission. |

## High-priority findings

| Priority | Finding | Recommendation |
| --- | --- | --- |
| Resolved | The old app icon was JPEG data named `.png` and included a baked rounded mask. | Replaced with a true RGB PNG whose artwork reaches every edge; regenerated every assigned size and preserved the previous icon files in `AppStore/LegacyAppIcon`. |
| Resolved | Word Mission could start as a one-letter recall task and produce an excessively tall writing surface. | Word missions now select genuine three-or-more-letter words and place the complete word on one continuous writing surface. |
| Resolved | Writing size, line controls, handedness and Pencil mode could be hidden in a partially expanded sheet. | Writing Tools now opens at the full-height detent; iPhone accurately says Finger drawing, while iPad exposes and tests Pencil-only mode. |
| Resolved | App Store Connect inherited stale 6.5-inch, 6.1-inch and 11-inch screenshot sets, causing older images to override the new media on those devices. | Removed those sets from the editable 1.2 draft. The sync now refuses inherited display sets, and the audit verifies the exact display-type set and MD5 checksum of every uploaded image. |
| P1 | iPadOS 26 launches the app as a resizable window by default. The UI adapted in the capture audit, but this materially increases the number of supported sizes. | Manually test narrow, wide, portrait, landscape, full-screen and side-by-side windows, especially writing-pad coordinate transforms and Circuit Challenge rotation. |
| P1 | The app contains generated/commissioned character art, icons, music and sound files. Code cannot establish their licence. | Keep provenance and commercial-use rights for every bundled visual and audio asset in the review file. |
| P1 | App Store privacy should be Data Not Collected only while all learning data and recordings remain on device. | Re-audit before every release and change the label before adding crash reporting, analytics, accounts, cloud sync or any server call. |
| P1 | The app asks for microphone access in a children's app. | Keep the request behind the existing adult gate, trigger it only from Record, and verify denial/recovery on a physical device. Explain this path in Review Notes. |
| P2 | iPhone and iPad Accessibility Nutrition Labels remain unpublished drafts. | This is currently voluntary. Publish only after all common tasks pass Apple's device-specific evaluation criteria; do not make untested VoiceOver, Voice Control, Larger Text or Reduced Motion claims. |

## Metadata and conversion review

- Name matches the installed display name and is within Apple's 30-character limit.
- Subtitle is within 30 characters and clearly covers the two core subjects.
- Promotional text is within 170 characters.
- Keywords are 90 ASCII bytes, contain no competitor names and do not repeat the app name.
- Description is plain text, avoids medical/developmental claims and describes only implemented features.
- Primary category is Education in Xcode and App Store Connect.
- Secondary category is Games with Family and Puzzle subcategories.
- App Store Connect has the truthful age-rating answers and Kids ages 6–8 band.
- Do not use “for kids” or equivalent metadata unless the app is enrolled in the Kids category.
- Do not claim COPPA/GDPR certification without legal review; the drafted privacy policy describes actual technical behaviour instead.

## Screenshot review

- Eight real in-app captures exist for the 6.9-inch iPhone class at 1320×2868.
- Eight real, full-screen captures exist for the 13-inch iPad class at 2048×2732.
- Upload-ready files are JPEG, opaque and within Apple's one-to-ten screenshot limit.
- The Debug-only screenshot router is excluded from Release builds and presents real production views.
- Do not upload the raw PNG captures because Simulator PNGs contain an alpha channel.
- Do not upload `Screenshots/iPad-13`; those are retained iPadOS 26 windowing audit captures and include the Home Screen. Use only `Screenshots/Upload-Ready`.
- The first three recommended screenshots show guided writing, whole-word writing and Circuit Challenge rather than a splash or login screen.
- The screenshots contain no fake scores, reviews, rankings, prices or unavailable features.

## Privacy and child-safety review

- iOS source audit found no URLSession, web view, advertising, tracking, analytics, cloud or third-party package in the app target.
- `PrivacyInfo.xcprivacy` declares no tracking or collected data and declares UserDefaults use with reason `CA92.1`.
- Profile names, scores, sampled traces, custom words and audio recordings are local.
- Optional reports and worksheets leave the app only through an adult-initiated system share sheet.
- Parent progress, profiles, reports, custom words and microphone recording use an adult-level multiplication gate.
- There is no account, chat, social feed, unrestricted browser, advertising or purchase flow.
- The public privacy and support pages are live over HTTPS and contain the product's existing developer contact details.

## Final manual release checklist

- [x] Replace every bracketed listing, privacy and support field.
- [x] Publish and load-test the privacy and support pages over HTTPS without login.
- [x] Confirm the existing public listing is already recommended for Kids ages 6–8.
- [x] Populate the truthful age-rating answers and Kids 6–8 selection.
- [x] Sync and independently audit the listing, review notes, categories and both eight-image screenshot sets.
- [ ] Select Data Not Collected and verify the privacy label preview.
- [x] Replace the pre-masked app icon with an opaque edge-to-edge PNG and validate its asset catalogue.
- [ ] Confirm artwork, font, voice, sound and music rights.
- [ ] Test microphone Allow, Don't Allow, later Settings recovery and recording deletion on a real iPad.
- [ ] Test Pencil-only mode with Apple Pencil; confirm finger drawing is ignored but buttons still work.
- [ ] Test left-handed mode and all writing sizes/line settings on iPhone SE-class, Pro Max and iPad layouts.
- [ ] Test iPadOS 26 resizable windows and rotation while drawing.
- [ ] Run VoiceOver, Reduce Motion, Larger Text, silent-mode and interrupted-audio checks.
- [x] Archive version 1.2 build 4 with the distribution team, export the App Store IPA and upload it successfully.
- [x] Confirm build 4 is `VALID` and attached to version 1.2.
- [ ] Complete a clean-install smoke test from TestFlight with no developer settings or seeded data.
- [x] Enter the Review Notes and upload only the opaque files in `Screenshots/Upload-Ready`.
- [x] Confirm the inherited Free price, availability record, export-compliance flag, content-rights declaration and complete review contact.
- [ ] Confirm DSA trader status, agreements, asset rights and the App Privacy preview in the web interface.
- [ ] Use manual release or a phased release for the first version after this large feature update.

## Prepared App Store Connect sync

The release sync validates the bundle/app IDs, creates or updates version 1.2 with manual release, writes the localisations, categories, truthful age-rating answers and review notes, uploads both ordered screenshot sets, and attaches processed build 4. It intentionally never calls a submission or release endpoint.

```sh
ASC_ISSUER_ID="<team issuer UUID>" ruby ios-app/AppStore/sync_app_store_connect.rb
```

The companion audit is read-only and verifies the stored listing, pricing, Kids enrollment, review contact, build, screenshot delivery state and absence of a submission:

```sh
ASC_ISSUER_ID="<team issuer UUID>" ruby ios-app/AppStore/audit_app_store_connect.rb
```

## Official sources

- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple metadata field definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple Kids category guidance](https://developer.apple.com/kids/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
- [Apple Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
