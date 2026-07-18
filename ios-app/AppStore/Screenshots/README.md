# App Store screenshots

## Upload-ready sets

- `Upload-Ready/iPhone-6.9`: 8 opaque JPEGs, 1320×2868 pixels.
- `Upload-Ready/iPad-13`: 8 opaque JPEGs, 2048×2732 pixels.

Both sizes are accepted by App Store Connect as of 14 July 2026. Upload one to ten images per device family. The recommended order is recorded in `../APP_STORE_LISTING.md`.

## Version 1.4 prepared sets

- `Prepared-1.4/iPhone-6.9`: 8 opaque JPEGs, 1320×2868 pixels.
- `Prepared-1.4/iPad-13`: 8 opaque JPEGs, 2048×2732 pixels.

These were recaptured from the final version 1.4 build 6 source on 18 July 2026, after the four-game UX fixes and full simulator verification. They lead with the real Dot-to-Dot number trail and the menu showing both Tap dots and Trace lines. The matching PNG capture masters are in `Prepared-1.4-Raw` and are not for upload.

## Capture provenance

- iPhone: iPhone 17 Pro Max simulator, iOS 26.2.
- iPad upload set: iPad Pro 12.9-inch (6th generation) simulator, iPadOS 16.1, captured full screen at an accepted 13-inch App Store size.
- Every image is a native Simulator capture of a real app view.
- Both complete eight-image sets were reviewed as contact sheets, with the Dot-to-Dot menu, guided letter C and iPad Comet Writer screens also inspected at original resolution.
- Storage was reset before each launch so the images do not expose a child's information.
- Status-bar battery and connectivity were normalised where supported.

## Non-upload folders

- `iPhone-6.9`: raw Simulator PNGs. They contain alpha and are retained only as capture masters.
- `iPad-13-fullscreen`: raw full-screen iPad PNGs. They contain alpha and are retained only as capture masters.
- `iPad-13`: iPadOS 26 resizable-window audit captures. They include the Home Screen and Dock and must not be submitted.
- `Prepared-1.4-Raw`: version 1.4 PNG capture masters. They retain alpha and must not be submitted.

Apple does not accept screenshot files with alpha channels. Use only the JPEGs under `Upload-Ready`.
