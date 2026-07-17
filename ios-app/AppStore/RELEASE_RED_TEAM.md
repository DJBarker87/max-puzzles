# App Store release red team

Reviewed: 17 July 2026

## Verdict

Version 1.3 (build 5) is submitted to App Review with status `WAITING_FOR_REVIEW`. Apple processed the uploaded build as `VALID`; the build is attached, both screenshot sets are complete, and the listing, categories, age rating and review information match the release payload. The pre-submission read-only API audit passed, then the current review-submission API flow created the submission, added version 1.3 and submitted it at 16:42 UTC on 16 July 2026. Release remains manual.

Version 1.4 (build 6) is the next prepared payload and has not been submitted by this implementation pass. Its local app changes have been red-teamed for UX and performance: the obsolete 100-picture Dot-to-Dot pack is removed in favour of 84 audited D1–D7 designs; semantic full-screen tap/Pencil colouring now requires real coverage; Star Speller adds the England Year 1 starter curriculum, contextual prompts, adaptive 3/5/10-word sessions and Comet Writer handwriting; and compact family progress can sync through Apple's private iCloud key-value store. No claim in the historical 1.3 evidence below should be read as a completed 1.4 archive, upload, physical-device or TestFlight check.

## Version 1.4 implementation evidence

- A clean iOS 26.2 simulator build succeeds with the iOS 16.0 deployment target.
- All 145 unit tests pass, including exact 84-picture catalogue enforcement, semantic colour plans, meaningful Pencil coverage, profile/cloud merging, contextual Year 1 prompts, three-key hints, adaptive mastery and durable session restoration.
- The menu artwork is held in a fixed viewport, ambient animation work is lifecycle/Reduce Motion aware, and Circuit text now scales with Dynamic Type.
- App-owned audio-session changes are centralised. Star Speller, Dot-to-Dot speech, Comet Writer speech and custom recordings suppress music for the full required-audio flow.
- Comet Writer now uses the system's ordinary British English letter names without spoken lowercase/uppercase labels. The experimental custom phoneme/IPA pronunciation layer and its curly/kicking letter wording are intentionally excluded from this release.
- The iCloud payload is compact and excludes detailed attempts, handwriting traces, custom words and recordings. Removed legacy Dot-to-Dot IDs are filtered from both local and cloud progress.
- The serial simulator UI suite covers all integrated product flows and launch configurations, including semantic-colouring close and Finished → More Pictures paths.

## Version 1.3 submission evidence (historical)

- All 107 unit tests pass, including coverage for every supported letter and number path.
- The final serial iPhone UI run passes 11 product-flow tests and four launch configurations with zero failures.
- The iPad writing-tools UI run passes, including the visible Pencil-only control and its off/on/off state changes.
- Four targeted profile/letter-learning unit tests pass, and the three-child add, relaunch and switch flow passes on iPhone 17 Pro and iPad (A16) simulators.
- Debug and Release simulator builds succeed for the iPhone target.
- Xcode's Release static analysis and shallow App Store bundle validation succeed.
- A generic-device archive and automatic App Store distribution export/upload both succeed.
- The archived payload is `com.maxpuzzles.app`, version 1.3, build 5, with iOS 16.0 minimum and `ITSAppUsesNonExemptEncryption = false`.
- Xcode uploaded build 5 successfully; Apple processed it as `VALID`, and it is attached to version 1.3.
- The live record has manual release, `usesIdfa = false`, a complete private review contact, no demo account, the existing Made for Kids enrollment and the existing Free price with GBR as the base territory.
- A read-only pre-submission audit confirms the only screenshot sets are the intended 6.9-inch iPhone and 13-inch iPad sets, all 16 images are `COMPLETE` and byte-match the local release files, and every stored metadata value matches the payload.
- A separate post-submission query confirms version 1.3, build 5 and the review submission are all `WAITING_FOR_REVIEW`.
- The Release app installs and launches successfully on an iPhone 17 Pro Max simulator.
- The Debug-only screenshot routing strings are absent from the Release executable.
- The built app contains its privacy manifest and the expected bundle ID, display name, version and microphone purpose string.
- Final screenshots were verified as opaque JPEGs: eight at 1320×2868 for 6.9-inch iPhone and eight at 2048×2732 for 13-inch iPad.

## Residual manual checks

| Priority | Finding | Required action |
| --- | --- | --- |
| Resolved | A public privacy policy is live at `https://maxis-mighty-mindgames-support.vercel.app/privacy`. | Entered into the prepared metadata payload. |
| Resolved | A public support page with the product's existing contact details is live at `https://maxis-mighty-mindgames-support.vercel.app/support`. | Entered into the prepared metadata payload. |
| Resolved | Version 1.2 is approved and ready for distribution, so its binary cannot be replaced. | This update was correctly advanced to version 1.3 build 5. |
| Resolved | The signed version 1.3 build 5 package needed to reach App Store Connect. | Upload, processing and version attachment all succeeded. |
| Resolved | The listing, screenshot sets, categories, Kids band, age rating and review details needed to be populated. | The authenticated sync completed and the independent read-only audit matches every prepared value. |
| P1 | DSA trader status and any additional App Store Connect agreements are account-level legal declarations that cannot be derived from the app. | App Store Connect accepted the submission under the existing account state; retain truthful selections and address any account-level request from Apple. |
| P1 | App privacy and content-rights provenance cannot be safely inferred or fully written through the current API. | Reconfirm Data Not Collected in App Store Connect against the 1.4 binary. The developer has no backend or access to the private Apple iCloud value, but the new off-device Apple service must be described accurately in the privacy policy and review notes. Keep asset-rights evidence on file. |
| P1 | Simulator testing cannot validate a real Apple Pencil, microphone hardware, real memory pressure or install-from-TestFlight behaviour. | Run the eventual 1.4 build through TestFlight on a supported iPhone and a Pencil-capable iPad before submission. |

## High-priority findings

| Priority | Finding | Recommendation |
| --- | --- | --- |
| Resolved | The old app icon was JPEG data named `.png` and included a baked rounded mask. | Replaced with a true RGB PNG whose artwork reaches every edge; regenerated every assigned size and preserved the previous icon files in `AppStore/LegacyAppIcon`. |
| Resolved | Word Mission could start as a one-letter recall task and produce an excessively tall writing surface. | Word missions now select genuine three-or-more-letter words and place the complete word on one continuous writing surface. |
| Resolved | Writing size, line controls, handedness and Pencil mode could be hidden in a partially expanded sheet. | Writing Tools now opens at the full-height detent; iPhone accurately says Finger drawing, while iPad exposes and tests Pencil-only mode. |
| Resolved | App Store Connect previously inherited stale 6.5-inch, 6.1-inch and 11-inch screenshot sets, causing older images to override newer media on those devices. | The 1.3 version contains only the managed 6.9-inch iPhone and 13-inch iPad sets; the audit verifies the exact display types and MD5 checksum of every uploaded image. |
| P1 | iPadOS 26 launches the app as a resizable window by default. The UI adapted in the capture audit, but this materially increases the number of supported sizes. | Manually test narrow, wide, portrait, landscape, full-screen and side-by-side windows, especially writing-pad coordinate transforms and Circuit Challenge rotation. |
| P1 | The app contains generated/commissioned character art, icons, music and sound files. Code cannot establish their licence. | Keep provenance and commercial-use rights for every bundled visual and audio asset in the review file. |
| P1 | App Store privacy answers must match the exact 1.4 binary. | Apple says developers are not responsible for data collected by Apple, and “collect” means off-device transmission that the developer or a third-party partner can access beyond servicing the request. Reconfirm the Data Not Collected answer in App Store Connect because private Apple iCloud progress is now implemented; change it before adding any developer backend, analytics or third-party SDK. |
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

- iOS source audit found no URLSession, web view, advertising, tracking, analytics, developer backend or third-party package in the app target. Version 1.4 does use Apple's `NSUbiquitousKeyValueStore` for compact private progress sync.
- `PrivacyInfo.xcprivacy` declares no tracking or collected data and declares UserDefaults use with reason `CA92.1`.
- Profile metadata and compact achievement summaries may sync privately through Apple iCloud. Detailed attempts, sampled traces, custom words and audio recordings remain local.
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
- [x] Archive version 1.3 build 5, export for App Store distribution and upload it successfully.
- [x] Confirm build 5 is `VALID` and attached to version 1.3.
- [ ] Complete a clean-install smoke test from TestFlight with no developer settings or seeded data.
- [x] Enter the Review Notes and upload only the opaque files in `Screenshots/Upload-Ready`.
- [x] Confirm the inherited Free price, availability record, export-compliance flag, content-rights declaration and complete review contact.
- [ ] Confirm DSA trader status, agreements, asset rights and the App Privacy preview in the web interface.
- [x] Use manual release for version 1.3.
- [x] Submit version 1.3 build 5 to App Review and verify `WAITING_FOR_REVIEW`.

## Prepared App Store Connect sync

The release sync validates the bundle/app IDs, creates or updates the version and build declared in `UploadPayload/app.json` (currently 1.4 build 6) with manual release, writes the localisations, categories, truthful age-rating answers and review notes, uploads both ordered screenshot sets, and attaches the processed build. It intentionally never calls a submission or release endpoint.

```sh
ASC_ISSUER_ID="<team issuer UUID>" ruby ios-app/AppStore/sync_app_store_connect.rb
```

The companion audit is read-only and verifies the stored listing, pricing, Kids enrollment, review contact, build, screenshot delivery state and absence of a submission:

```sh
ASC_ISSUER_ID="<team issuer UUID>" ruby ios-app/AppStore/audit_app_store_connect.rb
```

After that audit passes—and only after the current 1.3 review is resolved—the guarded submission command creates or reuses the iOS review submission, adds the version declared in the payload and submits it. It refuses to reuse an active submission targeting another version:

```sh
ASC_ISSUER_ID="<team issuer UUID>" ruby ios-app/AppStore/submit_app_store_review.rb
```

## Official sources

- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple metadata field definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple Kids category guidance](https://developer.apple.com/kids/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
- [Apple Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
- [Apple: Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
- [Apple App Store Connect API review submissions](https://developer.apple.com/documentation/appstoreconnectapi/review-submissions)
